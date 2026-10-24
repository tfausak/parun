module Parun.Types.TapForTotalPower where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Filter as Filter

-- | The payload of Parun.Types.CostComponent's TapForTotalPower arm (#1305): CR
-- 702.122a's crew cost.
--
-- PARAMETRIC in the keyword for the Filter it carries, exactly as
-- Parun.Types.CostComponent is.
--
-- totalPower is a THRESHOLD and not a count, which is CR 702.122a's "or
-- greater": how many objects are tapped is not determined by the cost at all.
-- That is why this is not Parun.Types.Sacrifice under another name -- see that
-- module.
data TapForTotalPower keyword = MkTapForTotalPower
  { totalPower :: Natural.Natural,
    whichPermanents :: Filter.Filter keyword
  }
  deriving (Eq, Ord, Show)
