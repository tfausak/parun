module Parun.Types.CombatDeclaration where

-- | CR 508.1 / 509.1: which of combat's two declarations a player makes -- the
-- attackers in the declare attackers step, or the blockers in the declare
-- blockers step.
data CombatDeclaration
  = -- | CR 508.1a: which creatures attack.
    Attackers
  | -- | CR 509.1a: which creatures block, and what each blocks.
    Blockers
  deriving (Bounded, Enum, Eq, Ord, Show)
