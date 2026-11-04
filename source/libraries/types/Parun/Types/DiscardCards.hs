module Parun.Types.DiscardCards where

import qualified Parun.Types.CardSelection as CardSelection
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectCount as ObjectCount

-- | The payload of Parun.Types.CostComponent's DiscardCards arm (#1620): CR
-- 601.2f's discard as a cost, discarding this many matching cards from the
-- paying player's hand.
--
-- PARAMETRIC in the keyword for the Filter it carries, exactly as
-- Parun.Types.CostComponent is.
--
-- count is Parun.Types.Sacrifice's reading and not
-- Parun.Types.TapForTotalPower's: the cards are counted exactly, unless it is
-- ObjectCount.Every, which picks nothing and so reads no selection.
--
-- selection is CR 701.9b's: the payer chooses unless the cost says at random,
-- which CR 601.2h pays in its second pass (Parun.Engine.Cost.paidInSecondPass).
--
-- The Filter admits everything for a cost that names no quality -- Cathartic
-- Reunion's "discard two cards" is @And []@ -- rather than the field being
-- optional. CR 701.9a's discard names a card either way, and one unconditional
-- reading keeps Parun.Engine.Cost.discardCandidates from having two.
--
-- The Filter is matched against the card's CR 613 projection, which is the
-- CostComponent arm's note rather than this record's.
data DiscardCards keyword = MkDiscardCards
  { count :: ObjectCount.ObjectCount,
    whichCards :: Filter.Filter keyword,
    selection :: CardSelection.CardSelection
  }
  deriving (Eq, Ord, Show)
