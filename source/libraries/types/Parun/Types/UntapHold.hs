module Parun.Types.UntapHold where

import qualified Numeric.Natural as Natural

-- | CR 502.3: what keeps a permanent an untap restriction names from untapping
-- during the untap step -- an effect's "can't" (CR 101.2), or the active
-- player's own determination of "which permanents they control will untap".
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
  deriving (Eq, Ord, Show)
