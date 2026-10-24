module Parun.Codec.LifeLossSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.LifeLoss as LifeLoss
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeLoss" $ do
  -- CR 119.3 is what a printing means, so the key is omitted: this is byte for
  -- byte what data/cards/ held when the payload was a PlayerQuantity.
  Spec.it s "an ordinary effect's loss omits the cause" $
    Common.assertCodec
      s
      LifeLoss.codec
      LifeLoss.MkLifeLoss
        { LifeLoss.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
          LifeLoss.quantity = Quantity.Literal 2,
          LifeLoss.cause = LifeLossCause.ByEffect,
          LifeLoss.tally = Nothing
        }
      " {\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  -- CR 728.1a, which only Parun.Engine.Rad mints.
  Spec.it s "rule 728.1's loss writes its cause" $
    Common.assertCodec
      s
      LifeLoss.codec
      LifeLoss.MkLifeLoss
        { LifeLoss.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
          LifeLoss.quantity = Quantity.Literal 1,
          LifeLoss.cause = LifeLossCause.ByRadiation,
          LifeLoss.tally = Nothing
        }
      " {\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"quantity\":{\"type\":\"Literal\",\"value\":1},\"cause\":{\"type\":\"ByRadiation\"}} "
  -- CR 702.101a's "the total life lost this way", the one caller that names a
  -- slot (Parun.Engine.Keyword.extort).
  Spec.it s "rule 702.101a's loss names a tally slot" $
    Common.assertCodec
      s
      LifeLoss.codec
      LifeLoss.MkLifeLoss
        { LifeLoss.player = PlayerRef.Relative PlayerRelation.Opponent,
          LifeLoss.quantity = Quantity.Literal 1,
          LifeLoss.cause = LifeLossCause.ByEffect,
          LifeLoss.tally = Just (SlotName.MkSlotName (Text.pack "extorted"))
        }
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}},\"quantity\":{\"type\":\"Literal\",\"value\":1},\"tally\":\"extorted\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeLoss.codec
