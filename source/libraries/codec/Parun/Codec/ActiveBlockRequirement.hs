{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveBlockRequirement where

import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.RequirementArity as RequirementArity
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveBlockRequirement as ActiveBlockRequirement

codec :: Codec.Codec ActiveBlockRequirement.ActiveBlockRequirement
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveBlockRequirement.source
  controller <- Fields.required "controller" PlayerId.codec ActiveBlockRequirement.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveBlockRequirement.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveBlockRequirement.expiry
  blocker <- Fields.required "blocker" (RestrictedCreatures.codec ObjectId.codec) ActiveBlockRequirement.blocker
  attacker <- Fields.required "attacker" (Common.maybe (RestrictedCreatures.codec ObjectId.codec)) ActiveBlockRequirement.attacker
  arity <- Fields.required "arity" RequirementArity.codec ActiveBlockRequirement.arity
  pure
    ActiveBlockRequirement.MkActiveBlockRequirement
      { ActiveBlockRequirement.source = source,
        ActiveBlockRequirement.controller = controller,
        ActiveBlockRequirement.timestamp = timestamp,
        ActiveBlockRequirement.expiry = expiry,
        ActiveBlockRequirement.blocker = blocker,
        ActiveBlockRequirement.attacker = attacker,
        ActiveBlockRequirement.arity = arity
      }
