module Parun.Types.RepeatPicks where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 732.3 inside a Parun.Types.RepeatIf: what each player has picked in the
-- run under way, and what each may not pick again while the runs keep
-- returning the game to the state they began in.
data RepeatPicks = MkRepeatPicks
  { -- | Picked in this run, by Parun.Engine.Resolve.Common.pickByChooser.
    picked :: !(Map.Map PlayerId.PlayerId (Set.Set ObjectId.ObjectId)),
    -- | No longer offered to that player (CR 732.3's "different game choice").
    refused :: !(Map.Map PlayerId.PlayerId (Set.Set ObjectId.ObjectId))
  }
  deriving (Eq, Ord, Show)
