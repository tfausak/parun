module Parun.Types.LifeChange where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 119.3: a player's life total moved, and by how much: GameEvent's LifeGained,
-- and Game.lifeChangeOf's reading of either direction.
data LifeChange = MkLifeChange
  { player :: PlayerId.PlayerId,
    amount :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
