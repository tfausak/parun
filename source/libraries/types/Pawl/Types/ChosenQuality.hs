module Pawl.Types.ChosenQuality where

-- | What Pawl.Types.Effect's ChooseQuality has the resolving controller choose
-- (CR 608.2d), written to the source as its as-enters twin writes it.
data ChosenQuality
  = -- | CR 105.1: one of the five colours, read back by Filter.HasChosenColor (Persecute).
    Color
  | -- | CR 305.6: one of the five basic land types, read back by Modification.SetLandSubtypeToChosen (Mystic Compass).
    BasicLandType
  deriving (Bounded, Enum, Eq, Ord, Show)
