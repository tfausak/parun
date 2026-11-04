module Parun.Types.AttackPermission where

import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttackWaiver as AttackWaiver
import qualified Parun.Types.Condition as Condition

-- | CR 702.3b / 302.6 / 613.11: one printed ATTACKING PERMISSION -- "this
-- creature can attack as though it didn't have defender" (Prison Barricade
-- kicked), "as though it had haste" (Instill Energy).
--
-- A permission rather than an arm of Parun.Types.CombatRestriction, for
-- Parun.Types.BlockPermission's reason: a restriction forbids a declaration and
-- this lifts one, so no reader of the one may read the other. It lifts its rule
-- alone: the creature still HAS defender, and still lacks haste.
--
-- Gathered LIVE from the battlefield on every read and never captured, the
-- posture every sibling carrier takes. Parun.Engine.AttackPermission is the only
-- module that reads it, and it answers a set of ids.
data AttackPermission = MkAttackPermission
  { -- | Which creatures it lets attack: Prison Barricade's own text is
    -- Affected.Matching Filter.IsSource.
    affected :: Affected.Affected,
    -- | CR 604.2's "as long as" (Drowsing Tyrannodon), BlockPermission.while's
    -- gate: re-read on every look against the full projection, the "you" inside
    -- it the source's controller. Nothing grants unconditionally.
    while :: Maybe Condition.Condition,
    -- | The attacking rule it lifts.
    waives :: AttackWaiver.AttackWaiver
  }
  deriving (Eq, Ord, Show)
