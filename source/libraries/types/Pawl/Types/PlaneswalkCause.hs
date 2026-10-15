module Pawl.Types.PlaneswalkCause where

-- | CR 701.31c: why a player would planeswalk, which Fixed Point in Time's "as a
-- result of rolling the planar die" reads.
data PlaneswalkCause
  = -- | CR 901.8: the planeswalking ability the planar die's Planeswalker symbol
    -- triggers.
    PlanarDie
  | -- | CR 704.6f: the state-based action for a face-up phenomenon.
    Phenomenon
  | -- | CR 701.31c: any other spell or ability that says to planeswalk.
    Instruction
  deriving (Bounded, Enum, Eq, Ord, Show)
