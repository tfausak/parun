{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveAttackRequirement where

import qualified Parun.Codec.AttackTarget as AttackTarget
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveAttackRequirement as ActiveAttackRequirement

codec :: Codec.Codec ActiveAttackRequirement.ActiveAttackRequirement
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveAttackRequirement.source
  controller <- Fields.required "controller" PlayerId.codec ActiveAttackRequirement.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveAttackRequirement.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveAttackRequirement.expiry
  attacker <- Fields.required "attacker" (RestrictedCreatures.codec ObjectId.codec) ActiveAttackRequirement.attacker
  defender <- Fields.defaulted "defender" Nothing (Common.maybe AttackTarget.codec) ActiveAttackRequirement.defender
  pure
    ActiveAttackRequirement.MkActiveAttackRequirement
      { ActiveAttackRequirement.source = source,
        ActiveAttackRequirement.controller = controller,
        ActiveAttackRequirement.timestamp = timestamp,
        ActiveAttackRequirement.expiry = expiry,
        ActiveAttackRequirement.attacker = attacker,
        ActiveAttackRequirement.defender = defender
      }
