module Parun.Types.CounterMotion where

import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 122: which way a counter trigger's counters moved.
data CounterMotion
  = -- | CR 122.6: put on by a player the relation admits (CR 122.6a's putter).
    Put PlayerRelation.PlayerRelation
  | -- | Removed, by anyone.
    Removed
  deriving (Eq, Ord, Show)
