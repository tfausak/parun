module Parun.Types.PhaseR where

import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PhaseRewrite as PhaseRewrite

-- | The payload of Parun.Types.ReplacementEffect's PhaseR arm: which beginnings
-- a skip intercepts (CR 614.1b / 500.11), and what it does with one.
data PhaseR effect = MkPhaseR
  { phases :: PhasePattern.PhasePattern,
    rewrite :: PhaseRewrite.PhaseRewrite effect
  }
  deriving (Eq, Ord, Show)
