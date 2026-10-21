module Pawl.Types.Prohibit where

import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Prohibition as Prohibition
import qualified Pawl.Types.RestrictedCreatures as RestrictedCreatures

-- | The payload of Pawl.Types.Effect's Prohibit arm: CR 101.2's "can't",
-- standing over the permanents 'affected' describes for 'duration' (CR 611.2a).
--
-- Hurr Jackal's is @Prohibit Regenerate UntilEndOfTurn (Named (InSlot
-- target))@; Deadlock Trap, Zirda, the Dawnwaker and Wall of Stolen Identity
-- write the other three Named. Exhaustion's is @Prohibit Untap
-- (DuringNextUntapStepOf target) (Matching ...)@.
--
-- One axis, where Pawl.Types.ForbidAttack also carries what the attack is aimed
-- at. Pawl.Types.RestrictedCreatures for that type's reason: CR 611.2c makes
-- "creatures and lands target opponent controls don't untap" a class.
--
-- Not a printed carrier (Pawl.Types.ActivationProhibition,
-- Pawl.Types.CombatRestriction, Pawl.Types.UntapRestriction): those are
-- gathered live off a SOURCE on the battlefield, where this outlives its source
-- (CR 611.2a).
--
-- No CR 605.1a kind for Activate: both printings of that sentence ("its
-- activated abilities can't be activated this turn", Deadlock Trap; Dovin
-- Baan's "until your next turn") name every activated ability. No CR 509.1b
-- "unless" gate for Block: no printing of this sentence states one.
data Prohibit = MkProhibit
  { what :: Prohibition.Prohibition,
    duration :: Duration.Duration,
    -- | Named for the permanents a ref picks at resolution (Hurr Jackal), Matching
    -- for CR 611.2c's class re-read whenever the prohibition is asked
    -- (Exhaustion).
    affected :: RestrictedCreatures.RestrictedCreatures ObjectRef.ObjectRef
  }
  deriving (Eq, Ord, Show)
