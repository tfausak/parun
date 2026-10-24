module Parun.Types.VotesReceived where

import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Quantity's VotesReceived arm: how many votes a
-- player received in the player vote whose tally @slot@ holds (CR 701.38a).
data VotesReceived = MkVotesReceived
  { slot :: SlotName.SlotName,
    player :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
