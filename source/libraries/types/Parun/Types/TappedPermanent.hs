module Parun.Types.TappedPermanent where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 106.12a: which permanent a tapped-for-mana trigger watches.
data TappedPermanent
  = -- | CR 303.4b: the permanent the bearer is attached to (Wild Growth's
    -- "enchanted land"), read live rather than through last known information.
    Attached
  | -- | A permanent the Filter admits (Autumn Willow, Harmony's "a land
    -- creature").
    Matching (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
