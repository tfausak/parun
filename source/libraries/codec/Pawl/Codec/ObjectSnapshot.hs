{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ObjectSnapshot where

import qualified Data.Set as Set
import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Codec.Zone as Zone
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Types.Zone as Zone

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec ObjectSnapshot.ObjectSnapshot
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec ObjectSnapshot.object
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec ObjectSnapshot.characteristics
  controller <- Fields.required "controller" (Common.maybe PlayerId.codec) ObjectSnapshot.controller
  owner <- Fields.required "owner" PlayerId.codec ObjectSnapshot.owner
  zone <- Fields.required "zone" Zone.codec ObjectSnapshot.zone
  home <- Fields.defaulted "home" Zone.Battlefield Zone.codec ObjectSnapshot.home
  lapsedGrants <- Fields.defaulted "lapsedGrants" Set.empty (Common.set Condition.codec) ObjectSnapshot.lapsedGrants
  pure
    ObjectSnapshot.MkObjectSnapshot
      { ObjectSnapshot.object = object,
        ObjectSnapshot.characteristics = characteristics,
        ObjectSnapshot.controller = controller,
        ObjectSnapshot.owner = owner,
        ObjectSnapshot.zone = zone,
        ObjectSnapshot.home = home,
        ObjectSnapshot.lapsedGrants = lapsedGrants
      }
