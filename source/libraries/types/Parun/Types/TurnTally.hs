module Parun.Types.TurnTally where

import qualified Data.Set as Set
import qualified Parun.Types.PlayerAction as PlayerAction

-- | What Parun.Types.Quantity's TalliedThisTurn counts a player doing this turn.
data TurnTally
  = -- | CR 701.9a: cards discarded, a cycled card included (CR 702.29a).
    CardsDiscarded
  | -- | CR 121.1: cards drawn -- Deem Inferior's "each card you've drawn this turn".
    CardsDrawn
  | -- | CR 603.1b / 608.2i: how many of these acts (Parun.Types.PlayerAction)
    -- were done, each counted once.
    ActionsDone (Set.Set PlayerAction.PlayerAction)
  | -- | CR 305.2a: lands played -- Fastbond's "if it wasn't the first land you
    -- played this turn".
    LandsPlayed
  deriving (Eq, Ord, Show)
