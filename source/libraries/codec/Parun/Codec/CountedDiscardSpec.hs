module Parun.Codec.CountedDiscardSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CountedDiscard as CountedDiscard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CountedDiscard" $ do
  -- The bound slot is ELIDED when absent, so this is byte-identical to what the
  -- two-field record wrote before the slot existed.
  Spec.it s "MkCountedDiscard, both keys" $
    Common.assertCodec
      s
      CountedDiscard.codec
      ( CountedDiscard.MkCountedDiscard
          { CountedDiscard.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "player")),
            CountedDiscard.quantity = Quantity.Literal 1,
            CountedDiscard.discarded = Nothing
          }
      )
      " {\"player\":{\"type\":\"InSlot\",\"value\":\"player\"},\"quantity\":{\"type\":\"Literal\",\"value\":1}} "
  Spec.it s "MkCountedDiscard, with the discarded slot" $
    Common.assertCodec
      s
      CountedDiscard.codec
      ( CountedDiscard.MkCountedDiscard
          { CountedDiscard.player = PlayerRef.Relative PlayerRelation.Opponent,
            CountedDiscard.quantity = Quantity.Literal 1,
            CountedDiscard.discarded = Just (SlotName.MkSlotName (Text.pack "discarded"))
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}},\"quantity\":{\"type\":\"Literal\",\"value\":1},\"discarded\":\"discarded\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CountedDiscard.codec
