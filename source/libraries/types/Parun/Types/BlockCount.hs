module Parun.Types.BlockCount where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 509.3: how a block trigger counts the creatures on the other side of
-- the block. Each Filter is over those creatures, as each became blocking (CR
-- 509.3f).
data BlockCount
  = -- | CR 509.3a / 509.3c: once each combat for the creature, naming no other.
    Once
  | -- | CR 509.3b / 509.3d: once for each admitted creature on the other side.
    EachCreature (Filter.Filter Keyword.Keyword)
  | -- | CR 509.3e: once as the admitted creatures on the other side reach at
    -- least this many.
    AtLeast Natural.Natural (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
