module Parun.Types.SkipPhase where

import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Uses as Uses

-- | CR 614.10: the players the PlayerRef names each skip matching phases.
--
-- `uses` and `duration` are CR 614.3's lifetime. Stonehorn Dignitary's "their
-- next combat phase" is Once and Indefinite (CR 614.10a's wait); False Peace's
-- "all combat phases of their next turn" is Unlimited over a
-- Duration.DuringNextTurnOf window; Moment of Silence's "their next combat phase
-- this turn" is Once until end of turn.
data SkipPhase = MkSkipPhase
  { player :: PlayerRef.PlayerRef,
    selector :: PhaseSelector.PhaseSelector,
    uses :: Uses.Uses,
    duration :: Duration.Duration
  }
  deriving (Eq, Ord, Show)
