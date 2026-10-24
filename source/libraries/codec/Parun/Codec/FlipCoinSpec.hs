module Parun.Codec.FlipCoinSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.FlipCoin as FlipCoin
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CoinReading as CoinReading
import qualified Parun.Types.FlipCoin as FlipCoin
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FlipCoin" $ do
  -- One coin flipped for a win, the only shape data/cards/ printed before Flock
  -- of Rabid Sheep: both defaults elide, so this is the wire form every earlier
  -- card already carries.
  Spec.it s "MkFlipCoin" $
    Common.assertCodec
      s
      FlipCoin.codec
      FlipCoin.MkFlipCoin
        { FlipCoin.count = Quantity.Literal 1,
          FlipCoin.reading = CoinReading.Wins,
          FlipCoin.slot = SlotName.MkSlotName (Text.pack "flip"),
          FlipCoin.misses = Nothing,
          FlipCoin.flipper = FlipCoin.defaultFlipper
        }
      " {\"slot\":\"flip\"} "
  Spec.it s "several coins read for their faces" $
    Common.assertCodec
      s
      FlipCoin.codec
      FlipCoin.MkFlipCoin
        { FlipCoin.count = Quantity.Literal 5,
          FlipCoin.reading = CoinReading.Heads,
          FlipCoin.slot = SlotName.MkSlotName (Text.pack "flip"),
          FlipCoin.misses = Nothing,
          FlipCoin.flipper = FlipCoin.defaultFlipper
        }
      " {\"count\":{\"type\":\"Literal\",\"value\":5},\"reading\":{\"type\":\"Heads\"},\"slot\":\"flip\"} "
  -- Both tallies of one instruction (Mutalith Vortex Beast).
  Spec.it s "a flip read for its wins and its losses" $
    Common.assertCodec
      s
      FlipCoin.codec
      FlipCoin.MkFlipCoin
        { FlipCoin.count = Quantity.Literal 1,
          FlipCoin.reading = CoinReading.Wins,
          FlipCoin.slot = SlotName.MkSlotName (Text.pack "won"),
          FlipCoin.misses = Just (SlotName.MkSlotName (Text.pack "lost")),
          FlipCoin.flipper = FlipCoin.defaultFlipper
        }
      " {\"misses\":\"lost\",\"slot\":\"won\"} "
  -- Mana Clash's second instruction: the target opponent's own flip.
  Spec.it s "a flip by a player a slot names" $
    Common.assertCodec
      s
      FlipCoin.codec
      FlipCoin.MkFlipCoin
        { FlipCoin.count = Quantity.Literal 1,
          FlipCoin.reading = CoinReading.Heads,
          FlipCoin.slot = SlotName.MkSlotName (Text.pack "theirHeads"),
          FlipCoin.misses = Just (SlotName.MkSlotName (Text.pack "theirTails")),
          FlipCoin.flipper = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))
        }
      " {\"flipper\":{\"type\":\"InSlot\",\"value\":\"target\"},\"misses\":\"theirTails\",\"reading\":{\"type\":\"Heads\"},\"slot\":\"theirHeads\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s FlipCoin.codec
