module Parun.Types.RemoveCountersAmong where

import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RemovalCount as RemovalCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.WhichCounters as WhichCounters

-- | The payload of Parun.Types.Effect's RemoveCountersAmong arm: counters of one
-- kind, or of any kind (Eventide's Shadow), off the permanents an ObjectRef names, the resolving controller dividing
-- them (CR 608.2d). An ObjectRef for Parun.Types.MoveCounters' `from`'s reason. `tally` binds how many came off, for "twice that many"
-- (Galloping Lizrog); Parun.Types.RemoveCounters' `tally`.
data RemoveCountersAmong = MkRemoveCountersAmong
  { count :: RemovalCount.RemovalCount,
    from :: ObjectRef.ObjectRef,
    kind :: WhichCounters.WhichCounters Keyword.Keyword,
    tally :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
