module Parun.Types.PhasePattern where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.PhaseSelector as PhaseSelector

-- | CR 614.1b / 500.11: which step-or-phase beginnings a SKIP intercepts. Eon Hub
-- is (Step (Beginning Upkeep)) for everybody; Stonehorn Dignitary is CombatPhase
-- for one player -- the whole of CR 506.1's five steps and none of them
-- individually.
--
-- `whosePhase` is CR 614.1's "does this instance apply" question asked about a
-- PLAYER, and for a step of the turn it applies only on that player's own turn.
-- Related AnyPlayer is every player (Stasis, Eon Hub), Related You the row's
-- controller (Necropotence's "skip your draw step"), and Among the player a
-- resolution named (Fatigue).
--
-- Among is BAKED by the engine, never authored: card data cannot name a player,
-- exactly as it cannot name Modification.SetController's. Parun.EffectLintSpec's "no
-- card authors a player-scoped phase skip" rejects one in card JSON, the same
-- treatment SetController's baked PlayerId gets (#199).
data PhasePattern = MkPhasePattern
  { whichPhase :: PhaseSelector.PhaseSelector,
    whosePhase :: ControllerRelation.ControllerRelation
  }
  deriving (Eq, Ord, Show)
