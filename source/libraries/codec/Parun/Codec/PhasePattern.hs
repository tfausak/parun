{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PhasePattern where

import qualified Parun.Codec.ControllerRelation as ControllerRelationCodec
import qualified Parun.Codec.SkipWindow as SkipWindow
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | `whosePhase`'s Among is runtime-only -- a player-scoped skip is baked by
-- Resolve's SkipPhase arm, not authored on a card -- but this codec is structural
-- over the record and so accepts one from card JSON: Parun.Codec.ActiveReplacement
-- round-trips a baked pattern through it. A corpus lint is what keeps the pool
-- honest instead, the same treatment SetController's PlayerId gets.
codec :: Codec.Codec PhasePattern.PhasePattern
codec = Fields.object $ do
  whichPhase <- Fields.required "whichPhase" SkipWindow.codec PhasePattern.whichPhase
  whosePhase <- Fields.defaulted "whosePhase" (ControllerRelation.Related PlayerRelation.AnyPlayer) ControllerRelationCodec.codec PhasePattern.whosePhase
  pure
    PhasePattern.MkPhasePattern
      { PhasePattern.whichPhase = whichPhase,
        PhasePattern.whosePhase = whosePhase
      }
