module Parun.Types.TurnTally where

-- | What Parun.Types.Quantity's TalliedThisTurn counts a player doing this turn.
data TurnTally
  = -- | CR 701.9a: cards discarded, a cycled card included (CR 702.29a).
    CardsDiscarded
  | -- | CR 121.1: cards drawn -- Deem Inferior's "each card you've drawn this turn".
    CardsDrawn
  | -- | CR 603.1b: which of the four bending verbs (CR 701.65b, 701.66b,
    -- 701.67c, 702.189b) were done -- Avatar Aang's "if you've done all four
    -- this turn".
    Bendings
  | -- | CR 305.2a: lands played -- Fastbond's "if it wasn't the first land you
    -- played this turn".
    LandsPlayed
  deriving (Bounded, Enum, Eq, Ord, Show)
