module Parun.Codec.ClauseSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Clause as Clause
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.Counter as Counter
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.IfTaken as IfTaken
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.OrElse as OrElse
import qualified Parun.Types.PayBranch as PayBranch
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The `card` parameter is instantiated at 'Text.Text' throughout, for
-- 'Parun.Codec.ModeSpec''s reason: the codec reaches it only through the supplied
-- Effect codec, so any type proves the shape.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

-- | And the `ability` parameter likewise: it too is reached only through the
-- codec supplied here, so any type proves the shape.
abilityCodec :: Codec.Codec Text.Text
abilityCodec = Common.text

codec :: Codec.Codec (Clause.Clause Text.Text Text.Text)
codec = Clause.codec cardCodec abilityCodec

toJson :: Clause.Clause Text.Text Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (Clause.Clause Text.Text Text.Text)
fromJson = Codec.decode codec

-- One constructor, so eight cases: a populated clause, CR 603.5's `optionality`
-- flag when present, CR 118.12's `payGate` when present, CR 701.46a's
-- `condition` gate when present, CR 608.2c's `ifTaken` naming one clause and
-- naming two, CR 608.2d's `orElse` branch when present, and every field
-- defaulted at once.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Clause" $ do
  Spec.it s "MkClause with one effect" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Attach (SlotName.MkSlotName (Text.pack "target")))))
      " {\"effects\":[{\"type\":\"Attach\",\"value\":\"target\"}]} "
  -- CR 603.5: an Optional clause is what a printed "may" encodes to, and the key
  -- is emitted only for that value.
  Spec.it s "an Optional clause's optionality key is present" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause Nothing Nothing Nothing (Optionality.Optional (PlayerRef.Relative PlayerRelation.You)) Nothing Seq.empty)
      " {\"optionality\":{\"type\":\"Optional\"}} "
  -- CR 608.2c: Tweeze's "If you do" names the ordinal of the clause it hangs
  -- off, and the key is emitted only when there is one.
  Spec.it s "a clause hanging off an earlier one writes the ifTaken key" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause (Just (IfTaken.AnyTaken (pure (ClauseIndex.MkClauseIndex 1)))) Nothing Nothing Optionality.Mandatory Nothing Seq.empty)
      " {\"ifTaken\":{\"type\":\"AnyTaken\",\"value\":[1]}} "
  -- CR 608.2d / 608.2c: Worms of the Earth's "if a player does either" hangs one
  -- clause off both halves of an either-or pair, so the key holds every ordinal
  -- it names.
  Spec.it s "a clause hanging off either of two writes both ordinals" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause (Just (IfTaken.AnyTaken (ClauseIndex.MkClauseIndex 0 NonEmpty.:| [ClauseIndex.MkClauseIndex 1]))) Nothing Nothing Optionality.Mandatory Nothing Seq.empty)
      " {\"ifTaken\":{\"type\":\"AnyTaken\",\"value\":[0,1]}} "
  -- CR 608.2d: Twiddle's tap names the untap it is exclusive with, and the key is
  -- emitted only when there is one. A DIFFERENT key from ifTaken, though both
  -- name clause ordinals: one clause may hang off an earlier one and branch
  -- against another, and a wire that fused them could not say which. The
  -- chooser is elided here, Twiddle's being the unmarked "you" (CR 405.4).
  Spec.it s "a clause exclusive with a sibling writes the orElse key" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause Nothing Nothing (Just (OrElse.MkOrElse (ClauseIndex.MkClauseIndex 1) (PlayerRef.Relative PlayerRelation.You) False)) Optionality.Mandatory Nothing Seq.empty)
      " {\"orElse\":{\"sibling\":1}} "
  -- CR 118.12a: Mana Leak's "unless its controller pays {3}" is what the
  -- payGate key encodes, and it is emitted only when there is one.
  Spec.it s "a clause carrying a resolution cost writes the key" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( Clause.MkClause
          Nothing
          Nothing
          Nothing
          Optionality.Mandatory
          ( Just
              PayGate.MkPayGate
                { PayGate.payer = PlayerRef.HolderOfBound Holder.Controller Hop.Itself (SlotName.MkSlotName (Text.pack "spell")),
                  PayGate.cost = CostChoice.MkCostChoice (Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 3]), Cost.components = []} NonEmpty.:| []),
                  PayGate.basis = Nothing,
                  PayGate.branch = PayBranch.IfNotPaid,
                  PayGate.obligation = PayObligation.Optional,
                  PayGate.perEach = Nothing,
                  PayGate.x = Nothing,
                  PayGate.offeredAt = Nothing
                }
          )
          (Seq.singleton (Effect.Counter (Counter.MkCounter (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) Nothing Nothing Nothing)))
      )
      " {\"effects\":[{\"type\":\"Counter\",\"value\":{\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"}}}],\"payGate\":{\"payer\":{\"type\":\"HolderOfBound\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"hop\":{\"type\":\"Itself\"},\"slot\":\"spell\"}},\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":3}]},\"branch\":{\"type\":\"IfNotPaid\"}}} "
  -- CR 701.46a: adapt's "if this permanent has no +1/+1 counters on it".
  Spec.it s "a clause carrying a condition writes the key" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( Clause.MkClause
          Nothing
          (Just (Condition.Compares (Compares.MkCompares (Quantity.ObjectCounters CounterKind.PlusOnePlusOne) Comparison.Exactly (Quantity.Literal 0))))
          Nothing
          Optionality.Mandatory
          Nothing
          Seq.empty
      )
      " {\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"ObjectCounters\",\"value\":{\"type\":\"PlusOnePlusOne\"}},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  Spec.it s "an empty clause omits every default field" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing Seq.empty)
      " {} "
