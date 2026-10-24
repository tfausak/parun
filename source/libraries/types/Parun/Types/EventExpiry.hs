module Parun.Types.EventExpiry where

import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 611.2a: Duration.UntilEvent as the game remembers it -- the event, and
-- CR 109.5's "you" its criterion is read from, BAKED at arming time
-- (Parun.Engine.Expiry.arm) for Parun.Types.PaidExpiry's reason.
data EventExpiry = MkEventExpiry
  { controller :: PlayerId.PlayerId,
    event :: DurationEvent.DurationEvent
  }
  deriving (Eq, Ord, Show)
