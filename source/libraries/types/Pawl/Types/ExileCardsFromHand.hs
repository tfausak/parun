module Pawl.Types.ExileCardsFromHand where

import qualified Pawl.Types.CostAmount as CostAmount
import qualified Pawl.Types.Filter as Filter

-- | The payload of Pawl.Types.CostComponent's ExileCardsFromHand arm: CR 406.2
-- out of a hidden zone, paid by exiling exactly this many cards the payer
-- chooses from their own hand among the ones the Filter admits. Cadaverous
-- Bloom's "Exile a card from your hand" is the printing, and March of Wretched
-- Sorrow's "exile any number of black cards" the announced count (CR 601.2b).
data ExileCardsFromHand keyword = MkExileCardsFromHand
  { count :: CostAmount.CostAmount,
    whichCards :: Filter.Filter keyword
  }
  deriving (Eq, Ord, Show)
