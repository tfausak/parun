module Parun.Types.CounterGrouping where

-- | CR 603.2c: which occurrences a counter trigger counts in one event.
data CounterGrouping
  = -- | "Whenever a counter is removed": once per counter.
    EachCounter
  | -- | "Whenever one or more counters are put on a creature": once per
    -- permanent.
    EachPermanent
  | -- | "Whenever one or more counters are put on one or more creatures": once
    -- per batch.
    EachBatch
  deriving (Bounded, Enum, Eq, Ord, Show)
