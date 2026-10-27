module Parun.Types.SubtypeFamily where

-- | CR 205.3: which family a chosen subtype is applied as, for
-- Parun.Types.Modification's ChosenSubtype -- the two families a choice of a
-- subtype (Parun.Types.ChosenQuality) can name.
data SubtypeFamily
  = -- | CR 305.6 / 305.7: a basic land type (Convincing Mirage).
    BasicLandType
  | -- | CR 205.3m: a creature type (Adaptive Automaton).
    CreatureType
  deriving (Bounded, Enum, Eq, Ord, Show)
