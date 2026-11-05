module Parun.Types.FlipOutcome where

-- | CR 705.2: how a called coin flip came out for the player who called it.
data FlipOutcome
  = -- | CR 705.2: the flip came up as called.
    Won
  | -- | CR 705.2: the flip did not come up as called.
    Lost
  deriving (Bounded, Enum, Eq, Ord, Show)
