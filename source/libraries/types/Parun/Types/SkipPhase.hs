module Parun.Types.SkipPhase where

import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SkipWindow as SkipWindow
import qualified Parun.Types.Uses as Uses

-- | CR 614.10: the players the PlayerRef names each skip `count` matching steps, phases or turns.
--
-- `uses` and `duration` are CR 614.3's lifetime. Stonehorn Dignitary's "their
-- next combat phase" is Once and Indefinite (CR 614.10a's wait); False Peace's
-- "all combat phases of their next turn" is Unlimited over a
-- Duration.DuringNextTurnOf window; Moment of Silence's "their next combat phase
-- this turn" is Once until end of turn.
--
-- `count` is CR 614.10a's "skip the next two": that many rows, each spent by
-- one occurrence. A Quantity, as on Parun.Types.TakeExtraTurn; one is the
-- value the codec elides. Eater of Days writes two.
--
-- Construct with BRACE syntax everywhere: positional construction absorbs a new
-- field in argument order with nothing red.
data SkipPhase = MkSkipPhase
  { player :: PlayerRef.PlayerRef,
    selector :: SkipWindow.SkipWindow,
    uses :: Uses.Uses,
    duration :: Duration.Duration,
    count :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)

-- | What "skip your next turn" writes, and the value the codec elides.
defaultCount :: Quantity.Quantity
defaultCount = Quantity.Literal 1
