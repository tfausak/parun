module Pawl.Types.GameLossR where

import qualified Data.Sequence as Seq
import qualified Pawl.Types.ControllerRelation as ControllerRelation

-- | The payload of Pawl.Types.ReplacementEffect's GameLossR arm: whose losses of
-- the game are intercepted (CR 104.3 / 614.1a), and the effects that happen
-- instead -- Lich's Mirror's reset.
--
-- Parametric in the effect for Pawl.Types.DamageR's reason.
data GameLossR effect = MkGameLossR
  { whose :: ControllerRelation.ControllerRelation,
    instead :: Seq.Seq effect
  }
  deriving (Eq, Ord, Show)
