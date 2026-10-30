module Parun.Types.ModeMemory where

-- | How long a modal instruction remembers the modes chosen for it, barring
-- them from later choices (CR 700.2a, 700.2b): Demonic Pact's "choose one that
-- hasn't been chosen".
data ModeMemory
  = -- | Any mode may be chosen. Every modal payload but the rider's bearers.
    NoMemory
  | -- | "that hasn't been chosen": barred while it is the same object (CR 400.7).
    ObjectLifetime
  deriving (Bounded, Enum, Eq, Ord, Show)
