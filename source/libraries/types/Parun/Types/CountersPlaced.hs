module Parun.Types.CountersPlaced where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 122.6: a player put counters of one kind on an object, with the count
-- BEFORE and the count AFTER (CR 714.2b's threshold crossing, which
-- neither count alone can answer). CR 122.6a's `putter` is what
-- "whenever you put" reads.
data CountersPlaced = MkCountersPlaced
  { putter :: PlayerId.PlayerId,
    object :: ObjectId.ObjectId,
    kind :: CounterKind.CounterKind Keyword.Keyword,
    before :: Natural.Natural,
    after :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
