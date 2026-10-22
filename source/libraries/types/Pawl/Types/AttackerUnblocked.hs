module Pawl.Types.AttackerUnblocked where

import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId

-- | CR 509.1h: an attacking creature became unblocked, and CR 508.5's
-- defending player for it, carried for Pawl.Types.AttackerBlocked's reason.
data AttackerUnblocked = MkAttackerUnblocked
  { attacker :: ObjectId.ObjectId,
    defender :: PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
