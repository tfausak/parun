module Pawl.Types.ForbidBeingBlocked where

import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | The payload of Pawl.Types.Effect's ForbidBeingBlocked arm: CR 509.1b's
-- restriction that no creature 'blockers' describes may block the attackers
-- 'affected' describes, for this duration. Veiling Oddity's "creatures can't be
-- blocked this turn" is @ForbidBeingBlocked UntilEndOfTurn (HasCardType
-- Creature) (HasCardType Creature)@; Space Beleren's "creatures in each sector
-- can be blocked this turn only by creatures in the same sector" bars every
-- blocker not in the attacker's sector, which is why 'blockers' is read in the
-- ATTACKER's context (Pawl.Types.CantBeBlockedBy's pairwise shape).
--
-- A class and never a named set, CR 611.2c's third sentence: the effect modifies
-- no characteristic, so it reaches creatures that were not on the battlefield
-- when it began. "Target creature can't be blocked this turn" names one object
-- and stays a granted Pawl.Types.CantBeBlockedBy.
data ForbidBeingBlocked = MkForbidBeingBlocked
  { duration :: Duration.Duration,
    affected :: Filter.Filter Keyword.Keyword,
    blockers :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
