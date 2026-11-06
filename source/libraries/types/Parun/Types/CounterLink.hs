module Parun.Types.CounterLink where

import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.CounterLinked as CounterLinked
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 607.1 / 607.5: an effect of `source`'s abilities acquired as
-- `acquisition` moved counters on an object, and which way.
-- Parun.Types.EntryLink's shape, plus what moved.
data CounterLink = MkCounterLink
  { source :: !ObjectId.ObjectId,
    acquisition :: !Acquisition.Acquisition,
    moved :: !(CounterLinked.CounterLinked Keyword.Keyword)
  }
  deriving (Eq, Ord, Show)
