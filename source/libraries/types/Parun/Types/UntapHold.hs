module Parun.Types.UntapHold where

import qualified Numeric.Natural as Natural

-- | CR 502.3: how an untap rule bears on the untap step's untap of the
-- permanents it names -- an effect's "can't" (CR 101.2), the active player's
-- own determination of "which permanents they control will untap", or an untap
-- in a step that is not their controller's.
--
-- Not Parun.Types.Optionality: that names WHO a printed "may" asks, and CR
-- 502.3 has already fixed who determines the untap, so a seat here could only
-- disagree with the rule.
data UntapHold
  = -- | It doesn't untap: "doesn't untap during its controller's untap step"
    -- (CR 101.2, CR 502.3).
    Forbidden
  | -- | Its controller may leave it tapped: "You may choose not to untap this
    -- artifact during your untap step" (CR 502.3).
    Elective
  | -- | No more than this many of them untap, the active player choosing which:
    -- "players can't untap more than two permanents during their untap steps"
    -- (CR 101.2, CR 502.3).
    AtMost Natural.Natural
  | -- | It untaps during each other player's untap step too: "Untap all
    -- permanents you control during each other player's untap step" (Seedborn
    -- Muse; CR 502.3, 613.11).
    DuringOthersSteps
  deriving (Eq, Ord, Show)
