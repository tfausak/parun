module Parun.Types.CounterHolder where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 603.2: whose counters a counter trigger watches.
data CounterHolder
  = -- | The bearer, compared by id (CR 715.2b's "this Saga").
    Self
  | -- | A permanent the Filter admits, judged with last known information (CR
    -- 608.2h).
    Permanent (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
