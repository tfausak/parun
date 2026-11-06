module Parun.Types.LifeChange where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 119.3: a player's life total moved, by how much, and whether it was their
-- first record in that direction this turn, stamped as it happened
-- (Parun.Engine.Event.lifeChanged) and again if CR 734.1 cuts an earlier one
-- (Parun.Engine.Event.restampLifeChanges).
data LifeChange = MkLifeChange
  { player :: PlayerId.PlayerId,
    amount :: Natural.Natural,
    first :: Bool
  }
  deriving (Eq, Ord, Show)
