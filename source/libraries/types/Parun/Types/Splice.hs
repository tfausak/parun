module Parun.Types.Splice where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Filter as Filter

-- | The payload of Parun.Types.Keyword's Splice arm: CR 702.47a's "Splice onto
-- [quality] [cost]".
--
-- PARAMETRIC in the keyword, for Parun.Types.Craft's reason. Only
-- @Splice Keyword.Keyword@ is ever written.
data Splice keyword = MkSplice
  { -- | The [quality], matched against the spell being cast.
    onto :: Filter.Filter keyword,
    -- | The [cost], paid as an additional cost (CR 601.2f-h).
    cost :: Cost.Cost keyword
  }
  deriving (Eq, Ord, Show)
