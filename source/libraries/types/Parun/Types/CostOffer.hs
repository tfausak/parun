module Parun.Types.CostOffer where

import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator

-- | CR 601.2b: what offered a candidate cost, as a scenario's cast names it
-- where the mana alone leaves two -- Henzie "Toolbox" Torre's blitz at a
-- spell's own mana cost (CR 702.152a). Read against
-- Parun.Types.CandidateCost.keyword.
data CostOffer
  = -- | CR 702: a keyword ability the designator names.
    ByKeyword (KeywordDesignator.KeywordDesignator Keyword.Keyword)
  | -- | CR 118.9: no keyword ability -- the printed cost, a printed alternative, or an effect's.
    ByNoKeyword
  deriving (Eq, Ord, Show)
