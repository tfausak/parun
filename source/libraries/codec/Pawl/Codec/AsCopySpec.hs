module Pawl.Codec.AsCopySpec where

import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Codec.AsCopy as AsCopy
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AsCopy as AsCopy
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Compares as Compares
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.CopyClause as CopyClause
import qualified Pawl.Types.CopyException as CopyException
import qualified Pawl.Types.CopyRecipient as CopyRecipient
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.DurationEvent as DurationEvent
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SetPowerToughness as SetPowerToughness
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Supertype as Supertype
import qualified Pawl.Types.WithCounters as WithCounters
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AsCopy" $ do
  -- CR 707.5: Clone's "any creature", excepting nothing -- the empty exception
  -- list is defaulted away.
  Spec.it s "MkAsCopy, no clauses: the key is omitted" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty Zone.Battlefield Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- CR 707.9d: Quicksilver Gargantuan's "except it's 7/7", beside the same
  -- eligible set.
  Spec.it s "MkAsCopy, an unconditional clause" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [CopyClause.MkCopyClause Nothing [CopyException.SetPowerToughness (SetPowerToughness.MkSetPowerToughness 7 7)] Nothing] False Seq.empty Zone.Battlefield Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"clauses\":[{\"exceptions\":[{\"type\":\"SetPowerToughness\",\"value\":{\"power\":7,\"toughness\":7}}]}]} "
  -- CR 614.1d inside CR 614.1c: Vesuva's "enter tapped as a copy".
  Spec.it s "MkAsCopy, entering tapped (Vesuva)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Land) [] True Seq.empty Zone.Battlefield Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"tapped\":true} "
  -- CR 707.9e: Altered Ego's "except it enters with X additional +1/+1 counters
  -- on it", the exception that is an additional effect. CR 107.3m's X is the
  -- announced one, spelled as the slot Pawl.Engine.Quantity.substituteAnnouncedX
  -- rewrites.
  Spec.it s "MkAsCopy, additional counters (Altered Ego)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [CopyClause.MkCopyClause Nothing [] (Just (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.InSlot (SlotName.MkSlotName (Text.pack "X")))))] False Seq.empty Zone.Battlefield Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"clauses\":[{\"counters\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"InSlot\",\"value\":\"X\"}}]}]} "
  -- CR 707.9g: the linked "when you do" trigger's effects, Wall of Stolen
  -- Identity's; the effect codec is a parameter, so text stands in for it.
  Spec.it s "MkAsCopy, a linked trigger (Wall of Stolen Identity)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False (Seq.fromList [Text.pack "tap", Text.pack "forbid"]) Zone.Battlefield Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"whenYouDo\":[\"tap\",\"forbid\"]} "
  -- CR 707.5 over a graveyard: Superior Spider-Man's "any creature card in a
  -- graveyard".
  -- CR 611.2a: Vesuvan Shapeshifter's "until this creature is turned face down".
  Spec.it s "MkAsCopy, with a duration (Vesuvan Shapeshifter)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty Zone.Battlefield (Just (Duration.UntilEvent DurationEvent.SourceTurnedFaceDown)) CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"duration\":{\"type\":\"UntilEvent\",\"value\":{\"type\":\"SourceTurnedFaceDown\"}}} "
  Spec.it s "MkAsCopy, from a graveyard (Superior Spider-Man)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty Zone.Graveyard Nothing CopyRecipient.ThisObject True)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"zone\":{\"type\":\"Graveyard\"}} "
  Spec.it s "MkAsCopy, onto its host and chosen (Metamorphic Alteration)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty Zone.Battlefield Nothing CopyRecipient.ItsHost False)
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"recipient\":{\"type\":\"ItsHost\"},\"optional\":false} "
  -- CR 707.9f: Spark Double's "it enters with an additional +1/+1 counter on it
  -- if it's a creature" beside its unconditional "it isn't legendary".
  Spec.it s "MkAsCopy, a conditional clause (Spark Double)" $
    Common.assertCodec
      s
      (AsCopy.codec Common.text Common.text)
      ( AsCopy.MkAsCopy
          (Filter.HasCardType CardType.Creature)
          [ CopyClause.MkCopyClause Nothing [CopyException.RemoveSupertypes (Set.singleton Supertype.Legendary)] Nothing,
            CopyClause.MkCopyClause (Just (Condition.Compares (Compares.MkCompares (Quantity.Literal 1) Comparison.AtLeast (Quantity.Literal 1)))) [] (Just (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1)))
          ]
          False
          Seq.empty
          Zone.Battlefield
          Nothing
          CopyRecipient.ThisObject
          True
      )
      " {\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"clauses\":[{\"exceptions\":[{\"type\":\"RemoveSupertypes\",\"value\":[{\"type\":\"Legendary\"}]}]},{\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":1},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"counters\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (AsCopy.codec Common.text Common.text)
