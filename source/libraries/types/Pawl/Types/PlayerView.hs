module Pawl.Types.PlayerView where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.SeatView as SeatView

-- | CR 400.2 / 723.4: everything one seat may see of a game, and nothing else.
data PlayerView = MkPlayerView
  { viewer :: PlayerId.PlayerId,
    turn :: Natural.Natural,
    phase :: Phase.Phase,
    active :: PlayerId.PlayerId,
    priority :: Maybe PlayerId.PlayerId,
    seats :: [SeatView.SeatView],
    battlefield :: [ObjectView.ObjectView],
    -- | Top first, as GameState.stack.
    stack :: [ObjectView.ObjectView],
    -- | This turn's log entries the seat witnessed (CR 400.2, 701.20a, 701.20e).
    witnessed :: [LoggedEvent.LoggedEvent],
    -- | The previous turn's log entries the seat witnessed, for a client that
    -- last looked before that turn ended (CR 514.1's discard, for one).
    witnessedLastTurn :: [LoggedEvent.LoggedEvent],
    result :: Maybe Result.Result
  }
  deriving (Eq, Show)
