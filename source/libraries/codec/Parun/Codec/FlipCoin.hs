{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FlipCoin where

import qualified Parun.Codec.CoinReading as CoinReading
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FlipCoin as FlipCoin

-- | A bare object keyed by the record's field names. Only `slot` is required: a
-- flip nothing reads is an effect with no observable outcome, where the other
-- four fields have the value all but a few cards in data\/cards\/ print.
codec :: Codec.Codec FlipCoin.FlipCoin
codec = Fields.object $ do
  count <- Fields.defaulted "count" FlipCoin.defaultCount Quantity.codec FlipCoin.count
  reading <- Fields.defaulted "reading" FlipCoin.defaultReading CoinReading.codec FlipCoin.reading
  slot <- Fields.required "slot" SlotName.codec FlipCoin.slot
  misses <- Fields.defaulted "misses" Nothing (Common.maybe SlotName.codec) FlipCoin.misses
  flipper <- Fields.defaulted "flipper" FlipCoin.defaultFlipper PlayerRef.codec FlipCoin.flipper
  pure FlipCoin.MkFlipCoin {FlipCoin.count = count, FlipCoin.reading = reading, FlipCoin.slot = slot, FlipCoin.misses = misses, FlipCoin.flipper = flipper}
