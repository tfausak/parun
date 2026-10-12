module Pawl.Types.Ballot where

import qualified Pawl.Types.BallotChoice as BallotChoice
import qualified Pawl.Types.PlayerId as PlayerId

-- | CR 701.38a: one vote, by one player, for one choice; an extra vote (CR
-- 701.38d) is a ballot of its own.
data Ballot = MkBallot
  { voter :: PlayerId.PlayerId,
    choice :: BallotChoice.BallotChoice
  }
  deriving (Eq, Ord, Show)
