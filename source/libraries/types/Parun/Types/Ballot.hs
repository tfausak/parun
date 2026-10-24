module Parun.Types.Ballot where

import qualified Parun.Types.BallotChoice as BallotChoice
import qualified Parun.Types.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 701.38a: one vote, by one player, for one choice; an extra vote (CR
-- 701.38d) is a ballot of its own.
data Ballot = MkBallot
  { voter :: PlayerId.PlayerId,
    choice :: BallotChoice.BallotChoice ObjectSnapshot.ObjectSnapshot
  }
  deriving (Eq, Ord, Show)
