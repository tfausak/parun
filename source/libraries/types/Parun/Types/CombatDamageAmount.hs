module Parun.Types.CombatDamageAmount where

-- | What a creature assigns in place of its power's combat damage. Ordered so
-- the greater wins over any timestamp (docs/decisions.md, "Whether assigning no
-- combat damage beats assigning toughness"; toughness over a power read as
-- positive is Loot, the Anomaly's ruling of 2026-08-21).
data CombatDamageAmount
  = -- | CR 510.1a, 107.1b: its power, a negative power read as positive (Loot, the Anomaly).
    PowerAsPositive
  | -- | CR 510.1a: equal to its toughness (Gauntlets of Light).
    EqualToToughness
  | -- | CR 510.1a: none at all (Orcish Squatters).
    NoCombatDamage
  deriving (Bounded, Enum, Eq, Ord, Show)
