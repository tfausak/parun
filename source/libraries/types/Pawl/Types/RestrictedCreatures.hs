module Pawl.Types.RestrictedCreatures where

import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | Which permanents a resolution-generated rules-modifying effect covers
-- (Pawl.Types.ForbidAttack, Pawl.Types.RequireAttack, Pawl.Types.RequireBlock
-- and Pawl.Types.Prohibit, and the rows they store). Creatures for every combat
-- carrier; Exhaustion's prohibition reaches lands too. The two arms are
-- CR 611.2c's two readings of a resolving continuous effect: the objects it
-- named when it began, and a class it re-reads thereafter.
--
-- PARAMETRIC in what the first arm names, Pawl.Types.AffectedPlayers' shape: a
-- card writes @RestrictedCreatures ObjectRef@ and the store holds
-- @RestrictedCreatures ObjectId@, the ref having been read once as the effect
-- began (CR 601.2c's slot is gone once the resolution is over).
data RestrictedCreatures named
  = -- | The permanents a ref names, read once at resolution -- Netter en-Dal's
    -- "target creature". A fixed object, not a class: CR 400.7 makes the same
    -- card returning a new object, so a frozen id is exactly the printed set.
    Named named
  | -- | CR 611.2c's third sentence: every permanent matching the Filter, re-read
    -- whenever the effect is asked -- Chronomantic Escape's "creatures". A
    -- restriction on a declaration modifies no characteristic and no controller,
    -- so it reaches permanents that were not on the battlefield when it began.
    Matching (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
