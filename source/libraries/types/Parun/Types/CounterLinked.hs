module Parun.Types.CounterLinked where

import qualified Parun.Types.CounterKind as CounterKind

-- | CR 607.1: which way a source's effect moved counters of one kind on an
-- object -- what Cyclopean Tomb's "a mire counter was put onto with this
-- artifact" and "a mire counter has not been removed from with this artifact"
-- read. Parametric in the keyword, Parun.Types.CounterKind's reason.
data CounterLinked keyword
  = -- | A counter of this kind was put onto the object (CR 122.6).
    PutWith (CounterKind.CounterKind keyword)
  | -- | A counter of this kind was removed from the object (CR 122.1).
    RemovedWith (CounterKind.CounterKind keyword)
  deriving (Eq, Ord, Show)
