module Parun.Types.BoundReading where

-- | Which incarnation of a bound object Parun.Types.Scope's OverBound counts.
data BoundReading
  = -- | CR 400.7j: the object the slot holds, wherever it wound up.
    AsBound
  | -- | CR 608.2h: the object a bound arrival was before the move that made it,
    -- read by last known information; Flood of Tears' "nontoken permanents you
    -- control" returned to hand.
    BeforeMove
  deriving (Bounded, Enum, Eq, Ord, Show)
