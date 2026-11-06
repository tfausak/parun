module Parun.Types.PendingSkipEffect where

import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.TurnMarker as TurnMarker

-- | CR 614.10b: an action a skip put first in the next step, phase or turn to
-- actually occur, with the turns still to come as the skip applied, which CR
-- 732.3's repeated-state check compares (Parun.Engine.Event's PhaseR arm).
data PendingSkipEffect = MkPendingSkipEffect
  { pending :: PendingReplacementEffect.PendingReplacementEffect,
    extraTurns :: [ExtraTurn.ExtraTurn],
    turnMarkers :: [TurnMarker.TurnMarker]
  }
  deriving (Eq, Ord, Show)
