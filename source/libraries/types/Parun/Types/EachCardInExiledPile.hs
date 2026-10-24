module Parun.Types.EachCardInExiledPile where

import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 607.2a: every card in exile in one of the effect's source's linked
-- piles, narrowed by the optional Filter -- Hoarding Dragon's "the exiled
-- card", Synthetic Split Reliquary's "each card exiled with its warden
-- ability". `filter` shadows the Prelude's, Parun.Types.Count's naming.
--
-- The Filter is OPTIONAL: Parun.Types.Filter has no tautological arm, so the
-- whole pile has no other spelling.
data EachCardInExiledPile = MkEachCardInExiledPile
  { pile :: ExiledPile.ExiledPile,
    filter :: Maybe (Filter.Filter Keyword.Keyword)
  }
  deriving (Eq, Ord, Show)
