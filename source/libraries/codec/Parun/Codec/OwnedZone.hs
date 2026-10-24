{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.OwnedZone where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PlayerRelation as PlayerRelation.Type

-- | A bare object keyed by the record's field names. The owner defaults to
-- AnyPlayer, the reading of a zone the text does not scope.
codec :: Codec.Codec OwnedZone.OwnedZone
codec = Fields.object $ do
  zone <- Fields.required "zone" Zone.codec OwnedZone.zone
  owner <- Fields.defaulted "owner" PlayerRelation.Type.AnyPlayer PlayerRelation.codec OwnedZone.owner
  pure OwnedZone.MkOwnedZone {OwnedZone.zone = zone, OwnedZone.owner = owner}
