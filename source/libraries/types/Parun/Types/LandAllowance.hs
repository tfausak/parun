module Parun.Types.LandAllowance where

import qualified Numeric.Natural as Natural

-- | CR 305.2: how far a continuous effect raises the number of lands a player
-- may play each turn.
data LandAllowance
  = -- | This many more (Exploration, Azusa, Lost but Seeking).
    Additional Natural.Natural
  | -- | Any number (Naya): CR 305.2a's comparison never forbids a play.
    AnyNumber
  deriving (Eq, Ord, Show)
