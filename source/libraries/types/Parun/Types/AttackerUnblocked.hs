module Parun.Types.AttackerUnblocked where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 509.1h: an attacking creature became unblocked, and CR 508.5's
-- defending player for it, carried for Parun.Types.AttackerBlocked's reason.
data AttackerUnblocked = MkAttackerUnblocked
  { attacker :: ObjectId.ObjectId,
    defender :: PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
