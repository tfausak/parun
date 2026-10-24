module Parun.Types.CostModifier where

import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.TurnScope as TurnScope

-- | The payload of Parun.Types.PlayerEffect's ModifyCost arm: CR 601.2f's
-- increase, reduction or additional cost, applied by a CR 613.11 effect to the
-- spells or the activations its subject names (Thalia, Sapphire Medallion,
-- Drought, Oppressive Rays, Heartstone, Brutal Suppression).
--
-- ONE record for both subjects because CR 602.2b applies CR 601.2b-i to an
-- activation "just as they apply to casting a spell": every criterion below
-- reads a step of that shared procedure, so it reads the same for either.
-- What only an activation has -- an ability among several on one object --
-- rides the subject (Parun.Types.ActivationCriteria).
data CostModifier = MkCostModifier
  { -- | Spells, or activated abilities and what narrows them.
    subject :: CostSubject.CostSubject,
    -- | The spell, or the activated ability's SOURCE object, matched against
    -- its projection: Thalia's "noncreature spells", Heartstone's "activated
    -- abilities of creatures".
    matching :: Filter.Filter Keyword.Keyword,
    -- | CR 601.2c: when Just, applies only where SOME announced target matches
    -- -- Kopala, Warden of Waves' "that target a Merfolk you control", Dwarven
    -- Mauler's "that target this creature". Once, however many match.
    whichTargets :: Maybe (Filter.Filter Keyword.Keyword),
    -- | CR 601.2c: when Just, the change applies once per DISTINCT announced
    -- target this matches -- Hinata, Dawn-Crowned's "{1} more to cast for each
    -- target", Battlefield Thaumaturge's "for each creature it targets".
    perTarget :: Maybe (Filter.Filter Keyword.Keyword),
    -- | CR 601.2f: when Just, the change applies this many times, read as the
    -- total is determined against the effect's source -- Henzie "Toolbox"
    -- Torre's "{1} less for each time you've cast your commander". Multiplies
    -- `perTarget`'s count where both are given.
    --
    -- Not implemented: baking the slots it reads when a resolving effect stores
    -- the change, Mutated Cultist's "for each counter removed this way" (#5153).
    perEach :: Maybe Quantity.Quantity,
    -- | Professor Hojo's "the FIRST activated ability you activate during your
    -- turn": Just a scope applies the change only in a turn the scope admits,
    -- and only to the first matching activation the player begins that turn --
    -- whether or not that one was changed, and whether or not this effect
    -- existed yet (Tezzeret, Betrayer of Flesh's ruling).
    --
    -- Not implemented for spells: Shadow in the Warp's "the first creature
    -- spell you cast each turn" (#4924); Parun.Codec.CostModifier refuses it.
    onlyFirst :: Maybe TurnScope.TurnScope,
    -- | What it does to the total cost.
    change :: CostChange.CostChange
  }
  deriving (Eq, Ord, Show)
