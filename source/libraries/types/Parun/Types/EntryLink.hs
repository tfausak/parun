module Parun.Types.EntryLink where

import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 607.1 / 607.5: what a permanent is linked to by entering: the object
-- whose ability put it onto the battlefield, and which acquisition of that
-- object's abilities the ability came with, since only that acquisition's
-- abilities refer to it.
data EntryLink = MkEntryLink
  { source :: !ObjectId.ObjectId,
    acquisition :: !Acquisition.Acquisition
  }
  deriving (Eq, Ord, Show)
