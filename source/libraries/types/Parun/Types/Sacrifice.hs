module Parun.Types.Sacrifice where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectCount as ObjectCount

-- | The payload of Parun.Types.CostComponent's Sacrifice arm (#1305): CR 701.21a
-- as a cost, sacrificing this many matching permanents, or every one.
--
-- PARAMETRIC in the keyword for the Filter it carries, exactly as
-- Parun.Types.CostComponent is.
--
-- A record of its OWN rather than one shared with
-- Parun.Types.TapForTotalPower: that constructor's number is a THRESHOLD on an
-- aggregate and this one's is HOW MANY objects, matched exactly, which is the
-- distinction the CostComponent arm spends a paragraph drawing.
data Sacrifice keyword = MkSacrifice
  { count :: ObjectCount.ObjectCount,
    whichPermanents :: Filter.Filter keyword
  }
  deriving (Eq, Ord, Show)
