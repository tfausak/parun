{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerAttacksWith where

import qualified Data.Text as Text
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerAttacksWith as PlayerAttacksWith

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.CreatureBecomesBlockedByAtLeast is. All three keys are required:
-- no part of the printed sentence has a default, an unfiltered "whenever you
-- attack" being Parun.Types.TriggerCondition's PlayerAttacks instead, and a
-- defaulted floor would let a card mean "one or more" by saying nothing.
--
-- The floor of one is 'Fields.objectWith''s check, Parun.Codec.EntersWith's
-- posture: a zero floor would fire on any declaration whatever the filter.
codec :: Codec.Codec PlayerAttacksWith.PlayerAttacksWith
codec =
  let check p =
        if PlayerAttacksWith.attackers p == 0
          then Left (Text.pack "attack trigger has a zero attackers floor")
          else Right p
   in Fields.objectWith check $ do
        player <- Fields.required "player" PlayerRelation.codec PlayerAttacksWith.player
        filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PlayerAttacksWith.filter
        attackers <- Fields.required "attackers" Common.natural PlayerAttacksWith.attackers
        pure
          PlayerAttacksWith.MkPlayerAttacksWith
            { PlayerAttacksWith.player = player,
              PlayerAttacksWith.filter = filter_,
              PlayerAttacksWith.attackers = attackers
            }
