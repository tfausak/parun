{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ExchangeCardZones where

import qualified Pawl.Codec.ObjectRef as ObjectRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ExchangeCardZones as ExchangeCardZones

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
