module Pawl.Types.ChosenCardInHand where

import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.Quantity as Quantity

-- | CR 402.3 with a choice: whose hand is looked in -- which is also who picks --
-- what may be picked, and HOW MANY.

-- ONE PlayerRef where Pawl.Types.ChosenCardInGraveyard needs a Chooser beside a
-- PlayerScope, because CR 402.3 collapses the chooser and the zone's owner onto
-- one seat. The fields are named rather than positional for that type's reason.
--
-- The COUNT is that type's: a Quantity of DISTINCT cards per hand, each pick
-- dropped from the candidates before the next ask (CR 608.2d), so Aquatic
-- Subtlety's "two cards from your hand" is one instruction over two cards (CR
-- 608.2f) rather than two choices that may name the same card. CR 609.3 covers
-- the shortfall.
data ChosenCardInHand = MkChosenCardInHand
  { player :: PlayerRef.PlayerRef,
    filter :: Filter.Filter Keyword.Keyword,
    count :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
