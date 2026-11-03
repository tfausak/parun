module Parun.Types.ZonePosition where

-- | Which cards of a library or graveyard Parun.Types.Scope's InPosition counts.
data ZonePosition
  = -- | CR 401.2 / 404.1: the top card (Vampire Nocturnus, Guiding Spirit).
    Top
  | -- | CR 404.1: the cards above the source, none if it isn't in that pile (Nether
    -- Shadow).
    AboveSource
  deriving (Bounded, Enum, Eq, Ord, Show)
