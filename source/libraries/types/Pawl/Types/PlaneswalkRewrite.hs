module Pawl.Types.PlaneswalkRewrite where

import qualified Data.Sequence as Seq

-- | CR 701.31b / 614.1a: how a replacement rewrites a planeswalk.
--
-- Parametric in the effect for Pawl.Types.DamageR's reason.
data PlaneswalkRewrite effect
  = -- | Susan Foreman's "instead look at the top two cards of your planar deck,
    -- put one on the bottom of your planar deck and the other on top, then
    -- planeswalk": the planeswalk still happens, after the arrangement.
    ArrangeTopTwo
  | -- | Fixed Point in Time's "chaos ensues instead": the planeswalk does not
    -- happen, and these effects do.
    RunEffects (Seq.Seq effect)
  deriving (Eq, Ord, Show)
