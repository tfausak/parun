module Parun.Types.PendingSkipEffect where

import qualified Data.Set as Set
import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.TurnMarker as TurnMarker

-- | CR 614.10b: an action a skip put first in the next step, phase or turn to
-- actually occur, with what CR 732.3's repeated-state check compares as the
-- skip applied (Parun.Engine.Event's PhaseR arm): the turns still to come and
-- the floating replacement rows standing.
data PendingSkipEffect = MkPendingSkipEffect
  { pending :: PendingReplacementEffect.PendingReplacementEffect,
    extraTurns :: [ExtraTurn.ExtraTurn],
    turnMarkers :: [TurnMarker.TurnMarker],
    -- | Each GameState.replacements row's timestamp, its CR 614.5 identity, so
    -- a lap that spent or swept one (Meditate's skip) is no repeat.
    replacements :: Set.Set Timestamp.Timestamp
  }
  deriving (Eq, Ord, Show)
