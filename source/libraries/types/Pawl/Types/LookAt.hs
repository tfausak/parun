module Pawl.Types.LookAt where

import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.SlotName as SlotName

-- | The payload of Pawl.Types.Effect's LookAt arm: WHICH cards CR 701.20e's look
-- shows, and the slot the resolution remembers them in.
--
-- Two fields rather than three, and the missing one is WHO looks. Rule 701.20e
-- shows the cards "only to the specified player". Not implemented: nothing
-- records who looks, so no look reaches Pawl.Engine.Visibility (#4391). The
-- ObjectRef says whose zone is looked in, which is as near as the state gets --
-- Into the Wilds names the controller's own library, Word of Command a targeted
-- opponent's hand.
data LookAt = MkLookAt
  { ref :: ObjectRef.ObjectRef,
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
