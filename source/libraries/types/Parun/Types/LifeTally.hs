module Parun.Types.LifeTally where

import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.WhichTurn as WhichTurn

-- | CR 119.3 / 608.2i: how much life a player gained or lost during a turn, the
-- payload of Parun.Types.Quantity's LifeChanged.
data LifeTally = MkLifeTally
  { player :: PlayerRef.PlayerRef,
    direction :: LifeDirection.LifeDirection,
    turn :: WhichTurn.WhichTurn
  }
  deriving (Eq, Ord, Show)
