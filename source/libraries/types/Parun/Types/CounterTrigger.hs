module Parun.Types.CounterTrigger where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.CounterGrouping as CounterGrouping
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterMotion as CounterMotion
import qualified Parun.Types.Keyword as Keyword

-- | CR 603.2 over CR 122.6's placement or a removal: which kind, which way, on
-- what, whether the count must cross a threshold, and per counter, per
-- permanent or per batch (CR 603.2c).
data CounterTrigger = MkCounterTrigger
  { kind :: CounterKind.CounterKind Keyword.Keyword,
    motion :: CounterMotion.CounterMotion,
    holder :: CounterHolder.CounterHolder,
    -- | The count crossing N the way the counters moved: CR 714.2b's "was less
    -- than N and became at least N" going on, CR 310.12b's last counter (N = 0)
    -- coming off. Nothing reads no count.
    threshold :: Maybe Natural.Natural,
    grouping :: CounterGrouping.CounterGrouping
  }
  deriving (Eq, Ord, Show)
