{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ExchangeCardZones where

import qualified Pawl.Codec.ObjectRef as ObjectRef
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ExchangeCardZones as ExchangeCardZones
import qualified Pawl.Types.ObjectRef as ObjectRef.Type
import qualified Pawl.Types.PlayerRef as PlayerRef.Type
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.TopOfLibrary as TopOfLibrary

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

-- TEMPORARY decode-only alias for the old ExchangeWithTopOfLibrary wire.
legacyTopOfLibrary :: Codec.Codec ExchangeCardZones.ExchangeCardZones
legacyTopOfLibrary = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec ExchangeCardZones.one
  player <- Fields.required "player" PlayerRef.codec (const (PlayerRef.Type.Relative PlayerRelation.You))
  pure (ExchangeCardZones.MkExchangeCardZones ref (ObjectRef.Type.TopOfLibrary (TopOfLibrary.MkTopOfLibrary player (Quantity.Literal 1))))
