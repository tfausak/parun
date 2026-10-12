module Pawl.Types.VotesReceived where

import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.SlotName as SlotName

-- | The payload of Pawl.Types.Quantity's VotesReceived arm: how many votes a
-- player received in the player vote whose tally @slot@ holds (CR 701.38a).
data VotesReceived = MkVotesReceived
  { slot :: SlotName.SlotName,
    player :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
