{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealsDamageToPlayer where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PermanentDealsCombatDamageToPlayer is. Both keys are required.
codec :: Codec.Codec DealsDamageToPlayer.DealsDamageToPlayer
codec = Fields.object $ do
  actor <- Fields.required "actor" ActingPermanent.codec DealsDamageToPlayer.actor
  recipient <- Fields.required "recipient" PlayerRelation.codec DealsDamageToPlayer.recipient
  pure DealsDamageToPlayer.MkDealsDamageToPlayer {DealsDamageToPlayer.actor = actor, DealsDamageToPlayer.recipient = recipient}
