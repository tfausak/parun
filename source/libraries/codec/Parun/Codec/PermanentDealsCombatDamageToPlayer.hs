{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentDealsCombatDamageToPlayer where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PermanentsDealCombatDamageToPlayer is. The first two keys are required: a
-- card that qualifies only the damager writes AnyPlayer for the recipient.
-- `orTheirPlaneswalkers` defaults to False.
codec :: Codec.Codec PermanentDealsCombatDamageToPlayer.PermanentDealsCombatDamageToPlayer
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentDealsCombatDamageToPlayer.filter
  recipient <- Fields.required "recipient" PlayerRelation.codec PermanentDealsCombatDamageToPlayer.recipient
  orTheirPlaneswalkers <- Fields.defaulted "orTheirPlaneswalkers" False Common.boolean PermanentDealsCombatDamageToPlayer.orTheirPlaneswalkers
  pure PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer {PermanentDealsCombatDamageToPlayer.filter = filter_, PermanentDealsCombatDamageToPlayer.recipient = recipient, PermanentDealsCombatDamageToPlayer.orTheirPlaneswalkers = orTheirPlaneswalkers}
