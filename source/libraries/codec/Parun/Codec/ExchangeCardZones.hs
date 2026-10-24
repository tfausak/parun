{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExchangeCardZones where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExchangeCardZones as ExchangeCardZones

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec ExchangeCardZones.ExchangeCardZones
codec = Fields.object $ do
  one <- Fields.required "one" ObjectRef.codec ExchangeCardZones.one
  other <- Fields.required "other" ObjectRef.codec ExchangeCardZones.other
  pure
    ExchangeCardZones.MkExchangeCardZones
      { ExchangeCardZones.one = one,
        ExchangeCardZones.other = other
      }
