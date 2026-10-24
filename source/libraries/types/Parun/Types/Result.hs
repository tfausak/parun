module Parun.Types.Result where

import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TeamId as TeamId

data Result
  = Won PlayerId.PlayerId
  | -- | CR 104.2c: a team won, and each player on it wins -- including one
    -- who had already lost.
    TeamWon TeamId.TeamId
  | Drawn
  deriving (Eq, Ord, Show)
