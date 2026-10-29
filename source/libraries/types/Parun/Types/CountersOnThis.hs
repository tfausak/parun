module Parun.Types.CountersOnThis where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.CounterKind as CounterKind

-- | The payload of Parun.Types.CostComponent's RemoveCountersFromThis and
-- PutCountersOnThis arms: this many counters of one kind, taken off or put on
-- the permanent the cost is on (CR 118.1). Barkhide Troll's +1\/+1 counter,
-- Hickory Woodlot's depletion counter and Yisan, the Wanderer Bard's verse
-- counter are printings.
--
-- PARAMETRIC in the keyword for the CounterKind it carries, exactly as
-- Parun.Types.CostComponent is.
data CountersOnThis keyword = MkCountersOnThis
  { kind :: CounterKind.CounterKind keyword,
    count :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
