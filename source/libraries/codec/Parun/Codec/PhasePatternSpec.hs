module Parun.Codec.PhasePatternSpec where

import qualified Parun.Codec.PhasePattern as PhasePattern
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerId as PlayerId

-- PhaseSelector's own coverage is in Parun.Codec.PhaseSelectorSpec; the three
-- cases here are MkPhasePattern's own axis -- a symmetric `whosePhase =
-- Nothing`, a baked `Just`, and a whole-phase selector.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PhasePattern" $ do
  Spec.it s "Eon Hub's symmetric whosePhase = Nothing" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep), PhasePattern.whosePhase = Nothing}
      " {\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}}}} "
  -- The only Just Resolve's SkipPhase arm produces, never authored on a
  -- card (#437).
  Spec.it s "Fatigue's player-scoped whosePhase = Just" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.DrawStep), PhasePattern.whosePhase = Just (PlayerId.MkPlayerId 1)}
      " {\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":{\"type\":\"DrawStep\"}}},\"whosePhase\":1} "
  -- CR 500.1: the whole-phase arm, once Resolve has baked the player its
  -- resolution named.
  Spec.it s "Stonehorn Dignitary's whole-phase selector" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.CombatPhase, PhasePattern.whosePhase = Just (PlayerId.MkPlayerId 1)}
      " {\"whichPhase\":{\"type\":\"CombatPhase\"},\"whosePhase\":1} "
  -- The defaulted field accepts an absent key and an explicit null alike, which
  -- is why its schema is nullable AND optional rather than one or the other.
  Spec.it s "reads an explicit null whosePhase" $
    Common.assertFromJson
      s
      (Codec.decode PhasePattern.codec)
      " {\"whichPhase\":{\"type\":\"CombatPhase\"},\"whosePhase\":null} "
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.CombatPhase, PhasePattern.whosePhase = Nothing}

  Spec.it s "has a schema" $
    Common.assertHasSchema s PhasePattern.codec
