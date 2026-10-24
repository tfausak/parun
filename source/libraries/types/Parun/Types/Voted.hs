module Parun.Types.Voted where

import Data.Set (Set)
import qualified Parun.Types.Ballot as Ballot
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 701.38a: a ballot was cast, and the players it was shown to -- every
-- player still in the game in an open vote, and in a secret one the voter and,
-- per CR 723.4, the player controlling the voter.
data Voted = MkVoted
  { ballot :: Ballot.Ballot,
    audience :: Set PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
