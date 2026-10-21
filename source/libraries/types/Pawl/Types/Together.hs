module Pawl.Types.Together where

-- | CR 601.2c: a restriction a slot's text places on its targets TOGETHER
-- rather than on each one -- every target of the slot sharing something.
data Together
  = -- | Decompose's "from a single graveyard", Misinformation's "from an
    -- opponent's graveyard": every target in one zone (CR 400.1).
    InOneZone
  deriving (Bounded, Enum, Eq, Ord, Show)
