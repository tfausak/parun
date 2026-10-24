{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LandPlayed where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LandPlayed as LandPlayed

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.LeftTheGame is. Every key is required.
codec :: Codec.Codec LandPlayed.LandPlayed
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec LandPlayed.player
  land <- Fields.required "land" ObjectId.codec LandPlayed.land
  from <- Fields.required "from" Zone.codec LandPlayed.from
  pure LandPlayed.MkLandPlayed {LandPlayed.player = player, LandPlayed.land = land, LandPlayed.from = from}
