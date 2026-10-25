module Parun.Types.EnteredZone where

import qualified Data.Set as Set
import qualified Parun.Types.Zone as Zone

-- | CR 400.7: which zone change made the candidate the object it is now -- the
-- payload of Parun.Types.Filter's EnteredThisTurn. Octomancer's "entered the
-- battlefield this turn" names only the destination; No Rest for the Wicked's
-- "put there from the battlefield this turn" names the origin as well.
data EnteredZone = MkEnteredZone
  { -- | The zone the candidate arrived in.
    to :: Zone.Zone,
    -- | The zones it may have come from; empty admits any.
    from :: Set.Set Zone.Zone
  }
  deriving (Eq, Ord, Show)
