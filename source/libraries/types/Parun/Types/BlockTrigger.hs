module Parun.Types.BlockTrigger where

import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 509.3: "whenever [a creature] blocks" (BlockRole.Blocker) or "becomes
-- blocked" (BlockRole.Attacker), the Filter naming that creature
-- (Filter.IsSource for the source's own), and how the other side is counted.
data BlockTrigger = MkBlockTrigger
  { role :: BlockRole.BlockRole,
    creature :: Filter.Filter Keyword.Keyword,
    count :: BlockCount.BlockCount
  }
  deriving (Eq, Ord, Show)
