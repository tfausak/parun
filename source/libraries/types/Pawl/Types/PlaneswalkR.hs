module Pawl.Types.PlaneswalkR where

import qualified Pawl.Types.ControllerRelation as ControllerRelation
import qualified Pawl.Types.PlaneswalkCause as PlaneswalkCause
import qualified Pawl.Types.PlaneswalkRewrite as PlaneswalkRewrite

-- | The payload of Pawl.Types.ReplacementEffect's PlaneswalkR arm: whose
-- planeswalks are intercepted (CR 701.31 / 614.1a), for which cause (Nothing
-- for any), and what happens instead.
--
-- Parametric in the effect for Pawl.Types.DamageR's reason.
data PlaneswalkR effect = MkPlaneswalkR
  { whose :: ControllerRelation.ControllerRelation,
    cause :: Maybe PlaneswalkCause.PlaneswalkCause,
    rewrite :: PlaneswalkRewrite.PlaneswalkRewrite effect
  }
  deriving (Eq, Ord, Show)
