{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CantAttackPlayer where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.AttackTargetKind as AttackTargetKind
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CantAttackPlayer as CantAttackPlayer

-- | Parun.Codec.CantBeBlockedBy's shape with the second key naming PLAYERS
-- instead of blockers: four named keys, the last of them CR 508.1c's "unless"
-- gate.
--
-- "kinds" is required rather than defaulted to OfPlayer alone: CR 506.3's list
-- has three entries and which of them a printing names is the sentence itself,
-- so a card file states it.
--
-- "defenders" and not a second "affected", for that codec's reason: the two keys
-- name opposite sides of one sentence, and naming them is what stops a card file
-- barring the restricted creatures from themselves.
--
-- "name" defaults to Nothing, Parun.Codec.AffectedUnless's reason.
codec :: Codec.Codec CantAttackPlayer.CantAttackPlayer
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec CantAttackPlayer.affected
  defenders <- Fields.required "defenders" PlayerScope.codec CantAttackPlayer.defenders
  kinds <- Fields.required "kinds" (Common.set AttackTargetKind.codec) CantAttackPlayer.kinds
  unless <- Fields.defaulted "unless" Nothing (Common.maybe Condition.codec) CantAttackPlayer.unless
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityName.codec) CantAttackPlayer.name
  pure
    CantAttackPlayer.MkCantAttackPlayer
      { CantAttackPlayer.affected = affected,
        CantAttackPlayer.defenders = defenders,
        CantAttackPlayer.kinds = kinds,
        CantAttackPlayer.unless = unless,
        CantAttackPlayer.name = name
      }
