module Parun.Types.Measure where

-- | A numeric characteristic read off an object's projected view
-- (Parun.Engine.Filter.measureOf), by a Parun.Types.Filter comparison or a
-- Parun.Types.Quantity.
data Measure
  = -- | CR 208.1: power.
    Power
  | -- | CR 208.1: toughness.
    Toughness
  | -- | CR 202.3: mana value.
    ManaValue
  | -- | CR 105.2: how many of the five colours the object is.
    ColorCount
  deriving (Bounded, Enum, Eq, Ord, Show)
