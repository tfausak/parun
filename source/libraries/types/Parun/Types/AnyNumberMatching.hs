module Parun.Types.AnyNumberMatching where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Quantity as Quantity

-- | CR 608.2d's plural choice of cards in a hand: which may be picked, and at
-- most how many. No ceiling is "any number". Parun.Types.AnyNumberDiscard's;
-- the battlefield's is Parun.Types.ChosenPermanents.
data AnyNumberMatching = MkAnyNumberMatching
  { filter :: Filter.Filter Keyword.Keyword,
    atMost :: Maybe Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
