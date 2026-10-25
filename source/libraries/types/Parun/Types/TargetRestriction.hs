module Parun.Types.TargetRestriction where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.StackObjectKind as StackObjectKind

-- | CR 115 / CR 101.2: one TARGETING PROHIBITION that is not a keyword --
-- "creatures can't be the targets of spells" (Dense Foliage).
--
-- Parun.Types.CrewRestriction's shape and filing, one game action over: CR
-- 613.11 puts a continuous effect that affects game rules outside the layer
-- system, and no layer of Parun.Engine.Projection rewrites it. Shroud and
-- hexproof (CR 702.18a, CR 702.11b) are abilities the object HAS; this one is
-- the source's, and grants the object nothing.
--
-- Gathered LIVE on every read and never captured, the posture every sibling
-- carrier takes: off the battlefield for a printed one, off the affected
-- player's rows for a resolved one.
--
-- PARAMETRIC in the affected set, Parun.Types.RestrictedCreatures' shape: a
-- printed carrier's is a Parun.Types.Affected, and Autumn's Veil's
-- Parun.Types.PlayerEffect.RestrictTargeting's a Filter over the permanents the
-- affected player controls.
--
-- Open-half card data, classified rather than identified:
-- Parun.Engine.TargetRestriction and Parun.Engine.PlayerEffect are the only
-- modules that may read it.
data TargetRestriction affected = MkTargetRestriction
  { -- | Which objects can't be targeted, re-derived every time it is asked (CR
    -- 613.11), as Parun.Types.CrewRestriction's set is.
    affected :: affected,
    -- | CR 115.1's kind of spell or ability the prohibition stops. "Spells or
    -- abilities" is one row per kind.
    kind :: StackObjectKind.StackObjectKind,
    -- | Which of those spells or abilities it stops: Karplusan Strider's "blue
    -- or black spells", @And []@ for Dense Foliage's every spell. Matched
    -- against the aiming object's projection with the RESTRICTING permanent as
    -- the filter's source, Parun.Types.AttachRestriction's `attachers` framing.
    -- Unlike CR 702.11d's hexproof from a quality it names no controller, so
    -- the Strider's own controller's blue spell is stopped too.
    aimers :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
