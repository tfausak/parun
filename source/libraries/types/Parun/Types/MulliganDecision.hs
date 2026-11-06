module Parun.Types.MulliganDecision where

-- | CR 103.5: a player's per-round mulligan declaration. A sum type, not a Bool.
data MulliganDecision
  = Mulligan
  | Keep
  deriving (Bounded, Enum, Eq, Ord, Show)
