module Parun.Types.AttackPermission where

import qualified Parun.Types.Affected as Affected

-- | CR 702.3b / 613.11: one printed ATTACKING PERMISSION -- "this creature can
-- attack as though it didn't have defender" (Prison Barricade kicked).
--
-- A permission rather than an arm of Parun.Types.CombatRestriction, for
-- Parun.Types.BlockPermission's reason: a restriction forbids a declaration and
-- this lifts one, so no reader of the one may read the other. It lifts
-- defender's restriction alone; the creature still HAS defender.
--
-- Gathered LIVE from the battlefield on every read and never captured, the
-- posture every sibling carrier takes. Parun.Engine.AttackPermission is the only
-- module that reads it, and it answers a set of ids.
newtype AttackPermission = MkAttackPermission
  { -- | Which creatures may attack as though they lacked defender: Prison
    -- Barricade's own text is Affected.Matching Filter.IsSource.
    affected :: Affected.Affected
  }
  deriving (Eq, Ord, Show)
