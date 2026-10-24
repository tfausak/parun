module Parun.Types.ManaAbilityResolved where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 605.3b's moment: an activated mana ability resolved, which permanent's it
-- was, and how much mana the activation produced. The payload of
-- Parun.Types.GameEvent's arm of the same name.
--
-- The PERMANENT and not an ability object, CR 605.3b leaving one uncreated: the
-- source stands in for it here the way it does in
-- Parun.Engine.Resolve.Effect.performManaAbility.
--
-- The AMOUNT is here for Parun.Types.TappedForMana's reason -- nothing on the
-- board can answer for it afterwards, the mana being a Parun.Types.ManaUnit in
-- some pool that carries no reference to its source and may already have been
-- spent. A count and not that event's set of types, because the rule this arm
-- serves is the one that reads "the amount of mana this creature produced"
-- (Tyvar the Bellicose); the types are CR 106.12a's question and
-- Parun.Types.TappedForMana answers it.
--
-- The WHOLE yield, not the activating player's share: CR 106.4 may split an
-- activation's mana between pools (Yurlok of Scorch Thrash), and "the amount of
-- mana this creature produced" asks what the permanent made rather than whose
-- pool it landed in -- Parun.Types.TappedForMana's `mana` is read the same way.
data ManaAbilityResolved = MkManaAbilityResolved
  { permanent :: ObjectId.ObjectId,
    amount :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
