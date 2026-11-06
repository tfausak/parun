module Parun.Types.RemoveFromCombat where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Unblocking as Unblocking

-- | What Effect.RemoveFromCombat removes, and what that leaves of the blocked
-- status of the attackers each was blocking (CR 506.4, CR 509.1h).
data RemoveFromCombat = MkRemoveFromCombat
  { removed :: ObjectRef.ObjectRef,
    unblocking :: Unblocking.Unblocking
  }
  deriving (Eq, Ord, Show)
