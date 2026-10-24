module Parun.Types.Cycling where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Filter as Filter

-- | The payload of Parun.Types.Keyword's Cycling arm (#1305): CR 702.29a's
-- discard-and-draw, plus CR 702.29e's typecycling as one field on it.
--
-- PARAMETRIC in the keyword, for Parun.Types.Cost's reason and one of its own:
-- the fields name a Cost and a Filter, both of which can name a Keyword, and
-- Keyword names THIS -- so a concrete record here would close the very module
-- cycle Parun.Types.Filter's parameter exists to keep open. Only
-- @Cycling Keyword.Keyword@ is ever written.
--
-- searchFor is Nothing for plain cycling and Just for typecycling, the
-- distinction CR 702.29f then makes invisible to every rule that looks for
-- cycling -- see the Keyword arm for why that is one constructor rather than
-- two.
data Cycling keyword = MkCycling
  { cost :: Cost.Cost keyword,
    searchFor :: Maybe (Filter.Filter keyword)
  }
  deriving (Eq, Ord, Show)
