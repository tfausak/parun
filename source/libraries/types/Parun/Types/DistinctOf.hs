module Parun.Types.DistinctOf where

-- | Which characteristic Parun.Types.Aggregation's Distinct counts the distinct
-- values of among the members: the size of the union of each member's set.
data DistinctOf
  = -- | CR 205.2a: card types (CR 208.2a's Tarmogoyf).
    CardTypes
  | -- | CR 105.1: colors, a colorless member adding nothing (CR 105.2c).
    Colors
  | -- | CR 205.3i / 305.6: Forest, Island, Mountain, Plains and Swamp, the
    -- domain count ("the number of basic land types among lands you control").
    BasicLandTypes
  | -- | CR 202.3: mana values, a member with no mana cost adding 0 (CR 202.3a).
    ManaValues
  | -- | CR 202.1: mana costs as symbols ({2}{B} is not {1}{B}{B}), a member with
    -- no mana cost adding nothing.
    ManaCosts
  deriving (Bounded, Enum, Eq, Ord, Show)
