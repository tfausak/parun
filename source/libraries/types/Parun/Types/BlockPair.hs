module Parun.Types.BlockPair where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 509.3b / 509.3d: which blocker and which attacker a pairwise block
-- trigger watches. Filter.IsSource is the source's own end (Loyal Sentry),
-- Filter.HasAttached its host's (Venom).
data BlockPair = MkBlockPair
  { blocker :: Filter.Filter Keyword.Keyword,
    attacker :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
