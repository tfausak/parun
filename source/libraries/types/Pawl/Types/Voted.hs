module Pawl.Types.Voted where

import Data.Set (Set)
import qualified Pawl.Types.Ballot as Ballot
import qualified Pawl.Types.PlayerId as PlayerId

-- | CR 701.38a: a ballot was cast, and the players it was shown to -- every
-- voter in an open vote, and in a secret one the voter and, per CR 723.4, the
-- player controlling the voter.
data Voted = MkVoted
  { ballot :: Ballot.Ballot,
    audience :: Set PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
