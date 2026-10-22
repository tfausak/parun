module Pawl.Types.GameOutcome where

-- | CR 104.2 / 104.3: which way out of the game an effect may preclude.
data GameOutcome
  = -- | CR 104.2: winning the game.
    Win
  | -- | CR 104.3: losing the game.
    Lose
  | -- | CR 704.5a / 810.8a: losing the game for having 0 or less life, and no
    -- other loss (Lich, Transcendence).
    LoseForZeroLife
  deriving (Bounded, Enum, Eq, Ord, Show)
