module Parun.Types.CounterChange where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 122: counters of one kind left an object, with the count BEFORE and the
-- count AFTER.

-- The pair rather than the amount, because CR 310.12b's Siege ability asks
-- whether the LAST counter left, which the amount alone can't answer.
--
-- BOTH counts are a Natural, which is why they are named: a swap would invert
-- every read of the last counter.
data CounterChange = MkCounterChange
  { object :: ObjectId.ObjectId,
    kind :: CounterKind.CounterKind Keyword.Keyword,
    before :: Natural.Natural,
    after :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
