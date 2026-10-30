module Parun.Types.ModeMemory where

-- | How long a modal instruction remembers the modes chosen for it, barring
-- them from later choices: Demonic Pact's "choose one that hasn't been chosen"
-- (its rulings). A barred mode can't be chosen, so CR 700.2b removes a
-- triggered ability left with none.
data ModeMemory
  = -- | Any mode may be chosen. Every modal payload but the rider's bearers.
    NoMemory
  | -- | "that hasn't been chosen": barred while it is the same object (CR 400.7).
    ObjectLifetime
  deriving (Bounded, Enum, Eq, Ord, Show)
