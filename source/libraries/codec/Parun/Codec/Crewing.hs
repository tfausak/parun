{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Crewing where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Crewing as Crewing

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec Crewing.Crewing
codec = Fields.object $ do
  vehicle <- Fields.required "vehicle" ObjectId.codec Crewing.vehicle
  crewedBy <- Fields.required "crewedBy" (Common.set ObjectId.codec) Crewing.crewedBy
  pure
    Crewing.MkCrewing
      { Crewing.vehicle = vehicle,
        Crewing.crewedBy = crewedBy
      }
