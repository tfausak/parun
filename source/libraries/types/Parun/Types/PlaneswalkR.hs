module Parun.Types.PlaneswalkR where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.PlaneswalkCause as PlaneswalkCause
import qualified Parun.Types.PlaneswalkRewrite as PlaneswalkRewrite

-- | The payload of Parun.Types.ReplacementEffect's PlaneswalkR arm: whose
-- planeswalks are intercepted (CR 701.31 / 614.1a), for which cause (Nothing
-- for any), and what happens instead.
--
-- Parametric in the effect for Parun.Types.DamageR's reason.
data PlaneswalkR effect = MkPlaneswalkR
  { whose :: ControllerRelation.ControllerRelation,
    cause :: Maybe PlaneswalkCause.PlaneswalkCause,
    rewrite :: PlaneswalkRewrite.PlaneswalkRewrite effect
  }
  deriving (Eq, Ord, Show)
