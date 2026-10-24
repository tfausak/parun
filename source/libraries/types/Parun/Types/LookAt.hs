module Parun.Types.LookAt where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's LookAt arm: WHICH cards CR 701.20e's look
-- shows, the slot the resolution remembers them in, and WHO looks. The ObjectRef
-- says whose zone is looked in -- Into the Wilds names the controller's own
-- library, Word of Command a targeted opponent's hand.
data LookAt = MkLookAt
  { ref :: ObjectRef.ObjectRef,
    slot :: SlotName.SlotName,
    looker :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
