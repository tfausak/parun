module Pawl.Types.DistinctOf where

-- | Which characteristic Pawl.Types.Aggregation's Distinct counts the distinct
-- values of among the members: the size of the union of each member's set.
data DistinctOf
  = -- | CR 205.2a: card types (CR 208.2a's Tarmogoyf).
    CardTypes
  | -- | CR 105.1: colors, a colorless member adding nothing (CR 105.2c).
    Colors
  | -- | CR 205.3i / 305.6: Forest, Island, Mountain, Plains and Swamp, the
    -- domain count ("the number of basic land types among lands you control").
    BasicLandTypes
  deriving (Bounded, Enum, Eq, Ord, Show)
