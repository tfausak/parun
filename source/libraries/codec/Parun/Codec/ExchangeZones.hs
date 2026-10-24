{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExchangeZones where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.ZonePair as ZonePair
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExchangeZones as ExchangeZones

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec ExchangeZones.ExchangeZones
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ExchangeZones.player
  zones <- Fields.required "zones" ZonePair.codec ExchangeZones.zones
  pure
    ExchangeZones.MkExchangeZones
      { ExchangeZones.player = player,
        ExchangeZones.zones = zones
      }
