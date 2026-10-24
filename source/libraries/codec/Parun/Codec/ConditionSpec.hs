module Parun.Codec.ConditionSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.Condition as Condition
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.DuringPhase as DuringPhase
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Condition" $ do
  -- Tagged, with the record's field names kept as the PAYLOAD's keys. The
  -- measured side is 3 and the threshold 5 deliberately: the two are the same
  -- type, so only an asymmetric fixture catches a codec that reads them in the
  -- wrong order.
  Spec.it s "Compares" $
    Common.assertCodec
      s
      Condition.codec
      (Condition.Compares (Compares.MkCompares (Quantity.Literal 3) Comparison.AtLeast (Quantity.Literal 5)))
      " {\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":3},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":5}}} "
  -- CR 702.100a's "and/or". Two disjuncts, and asymmetric ones, so a codec that
  -- dropped or reordered the list is caught.
  Spec.it s "Any" $
    Common.assertCodec
      s
      Condition.codec
      (Condition.Any [Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Power) Comparison.AtLeast (Quantity.Literal 1)), Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Toughness) Comparison.AtMost (Quantity.Literal 2))])
      " {\"type\":\"Any\",\"value\":[{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}},\"comparison\":{\"type\":\"AtMost\"},\"threshold\":{\"type\":\"Literal\",\"value\":2}}}]} "
  -- Nissa, Steward of Elements' conjunction. Two asymmetric conjuncts, for the
  -- disjunction's reason above.
  Spec.it s "All" $
    Common.assertCodec
      s
      Condition.codec
      (Condition.All [Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Power) Comparison.AtLeast (Quantity.Literal 1)), Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Toughness) Comparison.AtMost (Quantity.Literal 2))])
      " {\"type\":\"All\",\"value\":[{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}},\"comparison\":{\"type\":\"AtMost\"},\"threshold\":{\"type\":\"Literal\",\"value\":2}}}]} "
  -- Zurgo, Thunder's Decree's "during your end step": the window and the scope
  -- are both kept, as the activation rider's codec keeps them.
  Spec.it s "During" $
    Common.assertCodec
      s
      Condition.codec
      (Condition.During (DuringPhase.MkDuringPhase (PhaseSelector.Step (Phase.Ending EndingStep.EndStep)) TurnScope.ControllersTurn))
      " {\"type\":\"During\",\"value\":{\"window\":{\"type\":\"Step\",\"value\":{\"type\":\"Ending\",\"value\":{\"type\":\"EndStep\"}}},\"scope\":{\"type\":\"ControllersTurn\"}}} "
  -- The old untagged shapes are not conditions any more. A comparison's keys
  -- alone decoding would mean a card file written before #1304 kept working
  -- while writing something the schema does not describe.
  Spec.it s "rejects the untagged comparison shape" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " {\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}} ") >>= Codec.decode Condition.codec))
      "expected a decode failure"
  Spec.it s "rejects the untagged disjunction shape" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " {\"any\":[]} ") >>= Codec.decode Condition.codec))
      "expected a decode failure"
  -- Nesting, which is what makes Any a flat sibling arm rather than a wrapper.
  Spec.it s "Any nests" $
    Spec.assertEqWith
      s
      "preserved"
      (Codec.decode Condition.codec (Codec.encode Condition.codec (Condition.Any [Condition.Any []])))
      (Right (Condition.Any [Condition.Any []]))
  Spec.it s "All nests" $
    Spec.assertEqWith
      s
      "preserved"
      (Codec.decode Condition.codec (Codec.encode Condition.codec (Condition.All [Condition.All []])))
      (Right (Condition.All [Condition.All []]))
  -- Every Comparison, including both sides non-Count -- the shape an intervening
  -- "if" needs (CR 603.4). The
  -- registry-backed fixtures stay in Parun.CodecIntegrationSpec, shared with
  -- test-suite specs Parun.Codec cannot import.
  Spec.it s "round-trips at every comparison" $
    mapM_
      (\v -> Spec.assertEqWith s "preserved" (Codec.decode Condition.codec (Codec.encode Condition.codec v)) (Right v))
      [ Condition.Compares (Compares.MkCompares (Quantity.Count zeroSwamps) Comparison.Exactly (Quantity.Literal 0)),
        Condition.Compares (Compares.MkCompares (Quantity.Count zeroSwamps) Comparison.AtLeast (Quantity.Literal 3)),
        Condition.Compares (Compares.MkCompares (Quantity.Count zeroSwamps) Comparison.AtMost (Quantity.Literal 1)),
        Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Power) Comparison.AtLeast (Quantity.Literal 3))
      ]

-- A count with every axis non-default, so a codec that drops one is caught. The
-- zone is a GRAVEYARD rather than the battlefield because CR 400.1 gives each
-- player their own, which is what lets the reference beside it be a non-default
-- one: Parun.Codec.InZone rejects a shared zone scoped to anything but the whole
-- table.
zeroSwamps :: Count.Count Quantity.Quantity
zeroSwamps =
  Count.MkCount
    (Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.Opponent)))
    (Filter.HasSubtype Subtype.Swamp)
    Aggregation.Members
