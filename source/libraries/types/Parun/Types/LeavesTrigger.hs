module Parun.Types.LeavesTrigger where

import qualified Data.Set as Set
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.LeavingPermanent as LeavingPermanent
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

-- | CR 603.6c: a permanent leaving the battlefield -- which one, for which
-- zones, and per permanent or per batch (CR 603.2c).
data LeavesTrigger = MkLeavesTrigger
  { permanent :: LeavingPermanent.LeavingPermanent,
    -- | The destinations admitted, any one sufficing; empty for any departure,
    -- CR 603.6c's leaving the game included.
    destinations :: Set.Set OwnedZone.OwnedZone,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)

-- | "When this leaves the battlefield": the source, for anywhere, once per
-- permanent. The codec's defaults.
defaultValue :: LeavesTrigger
defaultValue =
  MkLeavesTrigger
    { permanent = LeavingPermanent.Self,
      destinations = Set.empty,
      batching = Batching.EachOccurrence
    }

-- | CR 700.4's "dies": the permanent is put into a graveyard, anyone's.
dies :: LeavingPermanent.LeavingPermanent -> LeavesTrigger
dies subject = defaultValue {permanent = subject, destinations = Set.singleton (OwnedZone.MkOwnedZone Zone.Graveyard PlayerRelation.AnyPlayer)}
