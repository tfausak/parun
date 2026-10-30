module Parun.Types.Trait where

-- | What two objects share: a non-empty intersection of their values, so an
-- object with none (a colourless one, a nameless one under CR 708.2a, one in no
-- sector) shares nothing. Compared between a candidate and an anchored object by
-- Parun.Types.Filter's Shares, and among members by Parun.Types.Aggregation's
-- MostSharing.
data Trait
  = -- | CR 105.2: a colour (CR 702.78a's conspire).
    Color
  | -- | CR 709.4a: a name (CR 702.60a's ripple).
    Name
  | -- | CR 108.3: the owner (CR 702.140a's mutate), never CR 109.5's "you",
    -- which is the controller. Parun.MutateSpec's "CR 702.140a a stolen mutate
    -- spell may target the owner's creature and not the caster's" proves the two
    -- part.
    Owner
  | -- | CR 702.158e: a sector designation.
    Sector
  | -- | CR 205.3m: a creature type.
    CreatureType
  | -- | CR 205.2a: a card type.
    CardType
  deriving (Bounded, Enum, Eq, Ord, Show)
