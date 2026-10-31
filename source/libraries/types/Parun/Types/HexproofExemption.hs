module Parun.Types.HexproofExemption where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 702.11e: what the player this applies to may target as though it didn't
-- have hexproof, Detection Tower's and Glaring Spotlight's grant. Every
-- "hexproof from [quality]" goes with plain hexproof (rule 702.11e); shroud and
-- protection stay.
data HexproofExemption = MkHexproofExemption
  { -- | The permanents exempted, CR 109.5's "you" being the aiming player.
    permanents :: Filter.Filter Keyword.Keyword,
    -- | Whether players are exempted too (CR 702.11c). Only an opponent's
    -- hexproof stops anyone, so "your opponents" needs no scope.
    players :: Bool
  }
  deriving (Eq, Ord, Show)
