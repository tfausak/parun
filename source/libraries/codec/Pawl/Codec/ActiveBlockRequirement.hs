{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ActiveBlockRequirement where

import qualified Pawl.Codec.Expiry as Expiry
import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Pawl.Codec.Timestamp as Timestamp
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ActiveBlockRequirement as ActiveBlockRequirement

codec :: Codec.Codec ActiveBlockRequirement.ActiveBlockRequirement
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveBlockRequirement.source
  controller <- Fields.required "controller" PlayerId.codec ActiveBlockRequirement.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveBlockRequirement.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveBlockRequirement.expiry
  blocker <- Fields.required "blocker" (RestrictedCreatures.codec ObjectId.codec) ActiveBlockRequirement.blocker
  attacker <- Fields.required "attacker" ObjectId.codec ActiveBlockRequirement.attacker
  pure
    ActiveBlockRequirement.MkActiveBlockRequirement
      { ActiveBlockRequirement.source = source,
        ActiveBlockRequirement.controller = controller,
        ActiveBlockRequirement.timestamp = timestamp,
        ActiveBlockRequirement.expiry = expiry,
        ActiveBlockRequirement.blocker = blocker,
        ActiveBlockRequirement.attacker = attacker
      }
