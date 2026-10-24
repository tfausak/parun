module Parun.Types.ManaOption where

import qualified Data.Map.Strict as Map
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Mana as Mana
import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 106.12: ONE way to tap a permanent for mana -- the cost CR 602.2b makes
-- that activation pay, paired with the whole yield it adds.
--
-- FIVE parts, strictly. The RIDER the ability prints about when it may be
-- activated (CR 602.5) rides along with the cost, because CR 605.3b gives a mana
-- ability no stack window for Parun.Engine.Activate to gate it in and
-- Parun.Engine.Cost.manaActivations is where CR 605.3a's two windows both ask
-- instead. A cost cannot carry it: Parun.Types.Cost is CR 118.1's payment and
-- says nothing about timing, and CR 305.6's intrinsic ability has a cost with no
-- ability to have printed a rider at all.
--
-- The ABILITY the route came from rides along for CR 602.5b's counted rider,
-- which is a fact about the ability rather than about the route and so can be
-- read off none of the other four parts:
-- Parun.Engine.ActivationRestriction.restrictionMet needs it to ask which ability
-- of this object has already been spent, and Parun.Engine.Cost.tapForManaWith
-- needs it to record the one it just spent. Nothing for CR 305.6's intrinsic
-- route, which is printed on no card and so is no ability's. Loot, the
-- Pathfinder's "{G}, {T}: Add three mana of any one color" is the printing, and
-- data/scenarios/mana's Loot boards are what prove it.
--
-- The cost and the yield both, because either alone loses a distinction the player is entitled
-- to make. The yield alone cannot separate an Urborg'd Mana Confluence's free
-- {B} from the {B} it charges 1 life for (#1117); the cost alone cannot separate
-- Birds of Paradise's five colours (CR 105.4).
--
-- VALUES throughout -- the cost, and the ability beside it -- rather than an
-- ordinal into the source's mana abilities, for Parun.Types.ReplacementEntry's
-- reason: two EQUAL abilities have to stay interchangeable, which value equality
-- gives and an ordinal does not, and there is no one list to index into, CR
-- 305.6's intrinsic ability being printed on no card and a member of nothing.
-- Two abilities alike in cost and yield but not in themselves are two options
-- and not one, which is the same rule read the other way: CR 602.5b's memory is
-- keyed to the ability, so spending one leaves the other.
data ManaOption = MkManaOption
  { cost :: Cost.Cost Keyword.Keyword,
    restrictions :: [ActivationRestriction.ActivationRestriction],
    -- | CR 602.5b: the ability this route is one selection of, or Nothing for CR
    -- 305.6's intrinsic one. See the note above the record.
    ability :: Maybe (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)),
    -- | CR 106.4: WHO gets WHAT -- the mana this activation adds, keyed by the
    -- reference each AddMana named its recipient with. Llanowar Elves' is a
    -- single @Relative You@ entry; Yurlok of Scorch Thrash's "Each player adds
    -- {B}{R}{G}" is a single @Relative AnyPlayer@ one, which is a different set of
    -- pools.
    --
    -- Keyed by the REFERENCE and not by a resolved PlayerId, because an option
    -- is enumerated off the card (Parun.Engine.Mana.manaOptionsOfGiven) and the
    -- roster it names is a fact about the board at the moment the ability is
    -- activated. Parun.Engine.Mana.recipientsOf is the one resolver both the
    -- payment (Parun.Engine.Cost.tapForManaWith) and the supply model
    -- (Parun.Engine.Mana.manaSuppliesGiven) read it through, so they cannot
    -- disagree about whose pool a route fills.
    --
    -- A Map and not a list of pairs, so two additions naming one reference
    -- collapse into one entry and Eq on the option stays the question "does this
    -- put the same mana in the same pools" -- Shizuko, Caller of Autumn spells
    -- {G}{G}{G} as three additions where another printing would write one of
    -- count 3. Printed order survives WITHIN a recipient's units, which is the
    -- only order CR 106.4 can observe: two pools have no order between them.
    yield :: Map.Map PlayerRef.PlayerRef Mana.Mana,
    -- | CR 608.2c: the selection's clauses in printed order, each with its
    -- share of `yield`, so the payment can decide each clause after the cost
    -- is paid (Parun.Engine.Cost.tapForManaWith) and CR 405.6c's other effects
    -- run from the clauses that happen. Ancient Tomb's "This land deals 2
    -- damage to you" is a clause with no share; Hickory Woodlot's "If there are
    -- no depletion counters on this land, sacrifice it" is one whose "if" the
    -- cost decides.
    --
    -- Part of the OPTION rather than looked up from the source afterwards, for
    -- the same reason the cost is: the option is what the player was offered,
    -- and two routes alike in cost and yield but not in what else they do are
    -- two options rather than one (ListUtils.nubOrd in
    -- Parun.Engine.Mana.manaOptionsOfGiven compares this too).
    steps :: [(Clause.Clause Card.Card (GrantedAbility.GrantedAbility Card.Card), Map.Map PlayerRef.PlayerRef Mana.Mana)]
  }
  deriving (Eq, Ord, Show)
