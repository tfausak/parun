module Pawl.Types.Trait where

-- | What Pawl.Types.Filter's SharesWithSource compares between the candidate
-- and the object the evaluation comes from: a non-empty intersection of the
-- two sides' values, so an object with none (a colourless one, a nameless one
-- under CR 708.2a, one in no sector) shares nothing.
data Trait
  = -- | CR 105.2: a colour (CR 702.78a's conspire).
    Color
  | -- | CR 201.2 / 709.4a: a name (CR 702.60a's ripple).
    Name
  | -- | CR 108.3: the owner (CR 702.140a's mutate), never CR 109.5's "you",
    -- which is the controller. Pawl.MutateSpec's "CR 702.140a a stolen mutate
    -- spell may target the owner's creature and not the caster's" proves the two
    -- part.
    Owner
  | -- | CR 702.158e: a sector designation.
    Sector
  deriving (Bounded, Enum, Eq, Ord, Show)
