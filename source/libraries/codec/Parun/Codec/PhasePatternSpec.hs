module Parun.Codec.PhasePatternSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.PhasePattern as PhasePattern
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- PhaseSelector's own coverage is in Parun.Codec.PhaseSelectorSpec; the
-- cases here are MkPhasePattern's own axis -- a symmetric `whosePhase`, the
-- row's own controller, a baked Among, and a whole-phase selector.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PhasePattern" $ do
  Spec.it s "Eon Hub's symmetric whosePhase" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep), PhasePattern.whosePhase = ControllerRelation.Related PlayerRelation.AnyPlayer}
      " {\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":\"Upkeep\"}}} "
  Spec.it s "Necropotence's whosePhase = Related You" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.DrawStep), PhasePattern.whosePhase = ControllerRelation.Related PlayerRelation.You}
      " {\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":\"DrawStep\"}},\"whosePhase\":{\"type\":\"You\"}} "
  -- The only Among Resolve's SkipPhase arm produces, never authored on a card
  -- (#437).
  Spec.it s "Fatigue's player-scoped whosePhase = Among" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.Step (Phase.Beginning BeginningStep.DrawStep), PhasePattern.whosePhase = ControllerRelation.Among (Set.singleton (PlayerId.MkPlayerId 1))}
      " {\"whichPhase\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":\"DrawStep\"}},\"whosePhase\":{\"type\":\"Among\",\"value\":[1]}} "
  -- CR 500.1: the whole-phase arm, once Resolve has baked the player its
  -- resolution named.
  Spec.it s "Stonehorn Dignitary's whole-phase selector" $
    Common.assertCodec
      s
      PhasePattern.codec
      PhasePattern.MkPhasePattern {PhasePattern.whichPhase = PhaseSelector.CombatPhase, PhasePattern.whosePhase = ControllerRelation.Among (Set.singleton (PlayerId.MkPlayerId 1))}
      " {\"whichPhase\":{\"type\":\"CombatPhase\"},\"whosePhase\":{\"type\":\"Among\",\"value\":[1]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PhasePattern.codec
