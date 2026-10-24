{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PhasePattern where

import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PhasePattern as PhasePattern

-- | `whosePhase` is runtime-only -- a player-scoped skip is baked by Resolve's
-- SkipPhase arm, not authored on a card -- but this codec is structural
-- over the record and so accepts one from card JSON. Nothing needs a baked
-- pattern to survive a round trip: neither Parun.Types.ActiveReplacement nor
-- GameState has a codec at all (#126). A corpus lint is what keeps the pool
-- honest instead, the same treatment SetController's PlayerId gets.
codec :: Codec.Codec PhasePattern.PhasePattern
codec = Fields.object $ do
  whichPhase <- Fields.required "whichPhase" PhaseSelector.codec PhasePattern.whichPhase
  whosePhase <- Fields.defaulted "whosePhase" Nothing (Common.maybe PlayerId.codec) PhasePattern.whosePhase
  pure
    PhasePattern.MkPhasePattern
      { PhasePattern.whichPhase = whichPhase,
        PhasePattern.whosePhase = whosePhase
      }
