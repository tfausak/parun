module Parun.Types.CounterPlacement where

import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A CR 122.6 placement PATTERN: which counter kind, which permanents count, and
-- who put the counters. Kind and permanents rather than a bare Filter, because the
-- printed form names both -- "whenever one or more -1\/-1 counters are put on one
-- or more creatures" -- and neither is recoverable from the other. `putter` is
-- AnyPlayer for that passive wording and You for "whenever you put" (Exemplar of
-- Light), against CR 122.6a's player.
--
-- Shared by BOTH of CR 603.2c's readings, which is why the type is named after
-- the pattern rather than after either constructor:
-- Parun.Types.TriggerCondition's PermanentGetsCounters names ONE permanent and
-- fires once per permanent, and its PermanentsGetCounters names a set and fires
-- once for the set. What differs is the scope, which is the constructor's, not
-- the pattern's -- the kind and the Filter are the same question either way.
data CounterPlacement = MkCounterPlacement
  { kind :: CounterKind.CounterKind Keyword.Keyword,
    permanents :: Filter.Filter Keyword.Keyword,
    putter :: PlayerRelation.PlayerRelation
  }
  deriving (Eq, Ord, Show)
