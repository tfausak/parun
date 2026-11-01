module Parun.Types.EntryOrigin where

import Numeric.Natural (Natural)
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Zone as Zone

-- | CR 614.12: where an entering permanent was before it moved, which is where
-- a count its entry makes still finds it (Parun.Engine.Projection.boardAsEntering).
data EntryOrigin = MkEntryOrigin
  { zone :: Zone.Zone,
    -- | CR 400.1: the player whose library, hand or graveyard held it; Nothing
    -- for a shared zone.
    holder :: Maybe PlayerId.PlayerId,
    -- | Its index from the head of that pile; 0 in a shared zone, which keeps
    -- no order.
    index :: Natural
  }
  deriving (Eq, Ord, Show)
