module Parun.Codec.DiscardSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Discard as Discard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.Discard as Discard
import qualified Parun.Types.EachCardInHand as EachCardInHand
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.ZoneScope as ZoneScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Discard" $ do
  -- CR 701.9b: the player the slot names discards this many, choosing which.
  Spec.it s "Counted" $
    Common.assertCodec
      s
      Discard.codec
      ( Discard.Counted
          CountedDiscard.MkCountedDiscard
            { CountedDiscard.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "player")),
              CountedDiscard.quantity = Quantity.Literal 1,
              CountedDiscard.discarded = Nothing
            }
      )
      " {\"type\":\"Counted\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"player\"},\"quantity\":{\"type\":\"Literal\",\"value\":1}}} "
  -- The card names the set instead, so CR 701.9b's choice does not arise --
  -- Amnesia's "discards all nonland cards".
  Spec.it s "These" $
    Common.assertCodec
      s
      Discard.codec
      (Discard.These (TheseDiscard.MkTheseDiscard (ObjectRef.EachCardInHand (EachCardInHand.MkEachCardInHand (ZoneScope.InSlot (SlotName.MkSlotName (Text.pack "target"))) (Just (Filter.Not (Filter.HasCardType CardType.Land))))) Nothing))
      " {\"type\":\"These\",\"value\":{\"cards\":{\"type\":\"EachCardInHand\",\"value\":{\"hands\":{\"type\":\"InSlot\",\"value\":\"target\"},\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}}}} "
  -- CR 107.1c: the players the reference names discard any number of matching cards.
  Spec.it s "AnyNumber" $
    Common.assertCodec
      s
      Discard.codec
      ( Discard.AnyNumber
          AnyNumberDiscard.MkAnyNumberDiscard
            { AnyNumberDiscard.player = PlayerRef.Relative PlayerRelation.You,
              AnyNumberDiscard.cards = AnyNumberMatching.MkAnyNumberMatching (Filter.HasCardType CardType.Land) Nothing,
              AnyNumberDiscard.discarded = Nothing
            }
      )
      " {\"type\":\"AnyNumber\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"cards\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Discard.codec
