module Parun.Types.LoyaltyGrant where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LoyaltyClause as LoyaltyClause

-- | CR 606.3 relaxed by an effect: the player may activate the loyalty abilities
-- of a matching permanent past that clause of the rule.
data LoyaltyGrant = MkLoyaltyGrant
  { relaxes :: LoyaltyClause.LoyaltyClause,
    -- | Which permanents, asked from the effect's source, so `IsSource` is "her
    -- loyalty abilities".
    permanents :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
