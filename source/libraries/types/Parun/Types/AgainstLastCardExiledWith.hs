module Parun.Types.AgainstLastCardExiledWith where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.Quantity's AgainstLastCardExiledWith arm: which of
-- the source's CR 607.2a linked cards to aim at -- the one matching `filter`
-- with the latest timestamp (CR 613.7d) -- then what to read off it.
--
-- PARAMETRIC in the quantity for Parun.Types.AgainstSlot's reason: the inner value
-- is a whole Quantity and Quantity names this record. `filter` shadows the
-- Prelude's, Parun.Types.Count's naming.
data AgainstLastCardExiledWith quantity = MkAgainstLastCardExiledWith
  { filter :: Filter.Filter Keyword.Keyword,
    quantity :: quantity
  }
  deriving (Eq, Ord, Show)
