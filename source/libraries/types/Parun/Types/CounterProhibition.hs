module Parun.Types.CounterProhibition where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.PlayerEffect's CantBeCountered arm (CR 701.6a /
-- 101.2): which spells and abilities can't be countered, and by what.
data CounterProhibition = MkCounterProhibition
  { -- | The victim's own qualities: Prowling Serpopard's "creature spells",
    -- Spider-Punk's @And []@ for every spell and ability.
    countered :: Filter.Filter Keyword.Keyword,
    -- | The countering spell or ability's, matched against the object on the
    -- stack and never its source: Autumn's Veil's "by blue or black spells",
    -- @And []@ for every one.
    counterers :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
