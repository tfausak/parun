module Pawl.Types.LimitUnless where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Condition as Condition

-- | A SIZE BOUND on how many creatures may be declared as blockers, the
-- attackers it is counted against, and CR 509.1b's "unless" gate. The bound
-- names no blocker, which is why the key is @limit@ rather than @affected@.

-- CombatRestriction's CantBlockMoreThan alone. It was shared with
-- CantAttackMoreThan until that one grew Pawl.Types.AttackLimitUnless's
-- `defenders`, which is the field this record's own note said would split them.
data LimitUnless = MkLimitUnless
  { limit :: Natural.Natural,
    -- | How a nonzero count of blockers must compare to the limit: AtMost is
    -- Charging Rhino's "can't be blocked by more than one creature", AtLeast
    -- Phyrexian Colossus' "can't be blocked except by three or more creatures".
    -- Blocking with none is never refused (CR 509.1b). Elided at AtMost.
    comparison :: Comparison.Comparison,
    -- | Nothing is the bound on the WHOLE declaration (Silent Arbiter), Just the
    -- bound on the creatures blocking EACH attacker it names, counted per
    -- attacker (Charging Rhino's "can't be blocked by more than one
    -- creature"). Pawl.Types.AttackLimitUnless's `defenders` on this side.
    -- Elided rather than written null.
    attackers :: Maybe Affected.Affected,
    -- | Nothing is the unconditional restriction. Elided rather than written
    -- null.
    unless :: Maybe Condition.Condition
  }
  deriving (Eq, Ord, Show)
