module Parun.Types.PlaysLand where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

-- | CR 305.1: whose land play fires the ability, the zone it is played from,
-- and which land -- Urianger Augurelt's "whenever you play a land from exile",
-- Fires of Mount Doom's "when you play a card this way".
data PlaysLand = MkPlaysLand
  { player :: PlayerRelation.PlayerRelation,
    from :: Zone.Zone,
    -- | Read against the land as it arrived (CR 400.7i).
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
