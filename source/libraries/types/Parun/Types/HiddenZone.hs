module Parun.Types.HiddenZone where

-- | CR 400.2: a hidden zone each player has their own of (CR 400.1), which
-- Parun.Types.RandomCard picks out of.
data HiddenZone
  = -- | CR 402.3.
    Hand
  | -- | CR 401.2.
    Library
  deriving (Bounded, Enum, Eq, Ord, Show)
