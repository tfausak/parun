module Parun.Types.AttackCompany where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Which other creatures an attacker trigger needs declared beside the
-- attacker.
data AttackCompany
  = -- | CR 508.3a: any, or none.
    AnyCompany
  | -- | CR 506.5: no other creature was declared.
    Alone
  | -- | CR 702.149a: at least one other attacking creature the Filter admits.
    WithAnother (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
