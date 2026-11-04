module Parun.Types.AttackCount where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 508.3c: "attacks with [n or more creatures]" -- at least this many
-- declared creatures the Filter admits (Military Intelligence's two).
data AttackCount = MkAttackCount
  { floor :: Natural.Natural,
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
