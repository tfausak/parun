module Pawl.Types.GameOutcome where

-- | CR 104.2 / 104.3: which way out of the game an effect may preclude.
data GameOutcome
  = -- | CR 104.2: winning the game.
    Win
  | -- | CR 104.3: losing the game.
    Lose
  deriving (Bounded, Enum, Eq, Ord, Show)
