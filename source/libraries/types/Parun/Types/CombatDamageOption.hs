module Parun.Types.CombatDamageOption where

-- | Where a creature's controller may have it assign all its combat damage
-- instead of where CR 510.1b-c send it.
data CombatDamageOption
  = -- | CR 510.1b-c: as though it weren't blocked (Lone Wolf).
    AsThoughUnblocked
  | -- | CR 510.1b: while unblocked, to one creature its defending player
    -- controls (Cunning Giant).
    ToDefendingCreature
  deriving (Bounded, Enum, Eq, Ord, Show)
