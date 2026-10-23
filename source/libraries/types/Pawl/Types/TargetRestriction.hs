module Pawl.Types.TargetRestriction where

import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.StackObjectKind as StackObjectKind

-- | CR 115 / CR 101.2: one printed TARGETING PROHIBITION that is not a keyword
-- -- "creatures can't be the targets of spells" (Dense Foliage).
--
-- Pawl.Types.CrewRestriction's shape and filing, one game action over: CR
-- 613.11 puts a continuous effect that affects game rules outside the layer
-- system, and no layer of Pawl.Engine.Projection rewrites it. Shroud and
-- hexproof (CR 702.18a, CR 702.11b) are abilities the object HAS; this one is
-- the source's, and grants the object nothing.
--
-- Gathered LIVE from the battlefield on every read and never captured, the
-- posture every sibling carrier takes.
--
-- Open-half card data, classified rather than identified:
-- Pawl.Engine.TargetRestriction is the only module that may read it.
data TargetRestriction = MkTargetRestriction
  { -- | Which objects can't be targeted, re-derived every time it is asked (CR
    -- 613.11), as Pawl.Types.CrewRestriction's set is.
    affected :: Affected.Affected,
    -- | CR 115.1's kind of spell or ability the prohibition stops. "Spells or
    -- abilities" is one row per kind.
    kind :: StackObjectKind.StackObjectKind
  }
  deriving (Eq, Ord, Show)
