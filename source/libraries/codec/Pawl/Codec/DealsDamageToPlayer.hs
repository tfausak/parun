{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.DealsDamageToPlayer where

import qualified Pawl.Codec.ActingPermanent as ActingPermanent
import qualified Pawl.Codec.PlayerRelation as PlayerRelation
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.DealsDamageToPlayer as DealsDamageToPlayer

-- | A bare object keyed by the record's field names, as
-- Pawl.Codec.PermanentDealsCombatDamageToPlayer is. Both keys are required.
codec :: Codec.Codec DealsDamageToPlayer.DealsDamageToPlayer
codec = Fields.object $ do
  actor <- Fields.required "actor" ActingPermanent.codec DealsDamageToPlayer.actor
  recipient <- Fields.required "recipient" PlayerRelation.codec DealsDamageToPlayer.recipient
  pure DealsDamageToPlayer.MkDealsDamageToPlayer {DealsDamageToPlayer.actor = actor, DealsDamageToPlayer.recipient = recipient}
