module Parun.Types.LoyaltyKind where

-- | CR 606.2's classification of one ACTIVATED ability, as a cost adjustment has
-- to ask it: Carth the Lion's "Planeswalkers' loyalty abilities you activate
-- cost an additional [+1] to activate".
--
-- The rulebook's own division and not an effect, the standing
-- Parun.Types.AbilityKind has for CR 605.1a: what the closed half compares here
-- is whether the ability being activated has a loyalty symbol in its cost
-- (Parun.Engine.Loyalty.isLoyaltyCost), never what that ability does.
--
-- BESIDE AbilityKind rather than a third arm of it, because the two rules cut
-- across each other: CR 605.1a divides mana from non-mana, CR 606.2 divides
-- loyalty from non-loyalty, and a loyalty ability is a non-mana ability under
-- the first while being the positive side of the second. One type holding both
-- would make an adjustment unable to say either without saying the other.
--
-- A TYPE and not a Bool, and read at two different scales, which is why one type
-- serves both: Parun.Engine.PlayerEffect.activationCostAdjustmentsGiven and
-- Parun.Engine.Filter's View are told which kind an ability IS, and
-- Parun.Types.ActivationCriteria.whichLoyalty and Filter.IsActivatedAbility say
-- which kind an adjustment or a filter APPLIES to (Chandra's Regulator).
data LoyaltyKind
  = -- | CR 606.2: a loyalty symbol in the ability's cost.
    LoyaltyAbility
  | -- | CR 606.2: every other activated ability, mana abilities included.
    NonLoyaltyAbility
  deriving (Bounded, Enum, Eq, Ord, Show)
