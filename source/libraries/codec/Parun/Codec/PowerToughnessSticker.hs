{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PowerToughnessSticker where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PowerToughnessSticker as PowerToughnessSticker

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec PowerToughnessSticker.PowerToughnessSticker
codec = Fields.object $ do
  tickets <- Fields.required "tickets" Common.natural PowerToughnessSticker.tickets
  power <- Fields.required "power" Common.integer PowerToughnessSticker.power
  toughness <- Fields.required "toughness" Common.integer PowerToughnessSticker.toughness
  pure
    PowerToughnessSticker.MkPowerToughnessSticker
      { PowerToughnessSticker.tickets = tickets,
        PowerToughnessSticker.power = power,
        PowerToughnessSticker.toughness = toughness
      }
