module Pawl.Types.Measure where

-- | A numeric characteristic read off an object's projected view
-- (Pawl.Engine.Filter.measureOf), by a Pawl.Types.Filter comparison or a
-- Pawl.Types.Quantity.
data Measure
  = -- | CR 208.1: power.
    Power
  | -- | CR 208.1: toughness.
    Toughness
  | -- | CR 202.3: mana value.
    ManaValue
  deriving (Bounded, Enum, Eq, Ord, Show)
