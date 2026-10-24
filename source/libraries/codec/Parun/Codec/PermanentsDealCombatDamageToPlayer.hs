{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentsDealCombatDamageToPlayer where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerAttacksPlayer is. The first two keys are required: a card
-- that qualifies only the damagers writes AnyPlayer for the recipient, which is
-- what "deal combat damage to a player" says. `oneOrMorePlayers` defaults to
-- that same "to a player".
codec :: Codec.Codec PermanentsDealCombatDamageToPlayer.PermanentsDealCombatDamageToPlayer
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentsDealCombatDamageToPlayer.filter
  recipient <- Fields.required "recipient" PlayerRelation.codec PermanentsDealCombatDamageToPlayer.recipient
  oneOrMorePlayers <- Fields.defaulted "oneOrMorePlayers" False Common.boolean PermanentsDealCombatDamageToPlayer.oneOrMorePlayers
  pure PermanentsDealCombatDamageToPlayer.MkPermanentsDealCombatDamageToPlayer {PermanentsDealCombatDamageToPlayer.filter = filter_, PermanentsDealCombatDamageToPlayer.recipient = recipient, PermanentsDealCombatDamageToPlayer.oneOrMorePlayers = oneOrMorePlayers}
