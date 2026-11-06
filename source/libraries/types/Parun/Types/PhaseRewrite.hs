module Parun.Types.PhaseRewrite where

import qualified Data.Sequence as Seq

-- | CR 614.10 / 614.1b: what a skip does with the step, phase or turn it
-- intercepts. Parun.Types.DrawRewrite's MaySkipFor is the draw's twin; the two
-- differ in WHEN the effects run, a skipped draw's at once and a skipped step's,
-- phase's or turn's as the next one to actually occur begins (CR 614.10b).
data PhaseRewrite effect
  = -- | CR 614.1b: replaced with nothing (Necropotence).
    Skip
  | -- | CR 614.10b: "you may skip that step instead. If you do, [these effects]"
    -- (Fasting, Time Vault), queued on Parun.Types.GameState's pendingSkipEffects.
    MaySkipFor (Seq.Seq effect)
  deriving (Eq, Ord, Show)
