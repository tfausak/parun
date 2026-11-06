module Parun.Types.TurnMarker where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 807.4: one Grand Melee turn marker, as an entry on
-- GameState.turnMarkers.
data TurnMarker = MkTurnMarker
  { -- | CR 807.4b: the number it was handed out with.
    number :: Natural.Natural,
    -- | CR 807.4c: the player holding it.
    holder :: PlayerId.PlayerId,
    -- | CR 807.4: whether its holder's turn is under way.
    underWay :: Bool,
    -- | CR 807.4c / 807.4i: whether its holder's ordinary turn under it is
    -- still to come, False once that turn has begun and while the marker is
    -- kept only for an extra turn.
    owesTurn :: Bool,
    -- | CR 807.4e / 807.4g: how many times it is designated for removal.
    removals :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
