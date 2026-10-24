module Parun.Types.CountersAre where

import Numeric.Natural (Natural)
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Reference as Reference

-- | CR 122.1: how many counters of one kind are on an object.
data CountersAre = MkCountersAre
  { object :: Reference.Reference,
    kind :: CounterKind.CounterKind Keyword.Keyword,
    count :: Natural
  }
  deriving (Eq, Ord, Show)
