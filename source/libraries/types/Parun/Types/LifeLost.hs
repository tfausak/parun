module Parun.Types.LifeLost where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 119.3: a player lost life, how much, and whether it was the first such
-- record of theirs this turn, stamped as it happened (Parun.Engine.Event.lifeLost).
data LifeLost = MkLifeLost
  { player :: PlayerId.PlayerId,
    amount :: Natural.Natural,
    first :: Bool
  }
  deriving (Eq, Ord, Show)
