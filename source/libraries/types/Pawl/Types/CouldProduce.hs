module Pawl.Types.CouldProduce where

import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ManaFilter as ManaFilter

-- | CR 106.7: one mana of a type some permanent the filter matches could
-- produce, of the types the mana filter admits -- Star Compass's "any color
-- that a basic land you control could produce" admits every type but colorless
-- (CR 105.4), Reflecting Pool's "any type" all six (CR 106.1b).
data CouldProduce = MkCouldProduce
  { among :: Filter.Filter Keyword.Keyword,
    types :: ManaFilter.ManaFilter
  }
  deriving (Eq, Ord, Show)
