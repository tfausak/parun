module Parun.Types.CombatDamageAmount where

-- | What a creature assigns in place of its power's combat damage. Ordered so
-- the greater wins over any timestamp (docs/decisions.md, "Whether assigning no
-- combat damage beats assigning toughness").
data CombatDamageAmount
  = -- | CR 510.1a: equal to its toughness (Gauntlets of Light).
    EqualToToughness
  | -- | CR 510.1a: none at all (Orcish Squatters).
    NoCombatDamage
  deriving (Bounded, Enum, Eq, Ord, Show)
