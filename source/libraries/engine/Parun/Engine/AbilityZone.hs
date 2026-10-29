-- CR 113.6: which zones an ACTIVATED ability functions from -- CR 113.6b's
-- stated zones, CR 113.6m's cost and effect halves, and the battlefield default
-- -- and CR 702.178b's question of where a grant of one functions.
--
-- Below Parun.Engine.Projection.View rather than in Parun.Engine.Activatable or
-- Parun.Engine.Cost, both of which sit above the projection: the view builder
-- asks it of an "as long as" grant (ActivatedAbility.condition) to decide
-- whether the object has the ability where it is. The cost half cases on
-- CostComponent here for the reason Parun.Engine.ManaAbility.costMovesLibraryCard
-- does: Parun.Engine.Cost is unreachable from below the projection.
module Parun.Engine.AbilityZone where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.EffectZone as EffectZone
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Card as Card
import Parun.Types.Cost (Cost)
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.Zone as Zone

-- CR 113.6m in full: "an ability whose cost OR EFFECT specifies that it moves
-- the object it's on out of a particular zone functions only in that zone".
-- Nothing for an ability that specifies neither, which leaves CR 113.6's own
-- default in place -- an instant or sorcery spell's abilities function on the
-- stack, everything else's on the battlefield.
--
-- The two halves are read by the two functions that own the two shapes:
-- costZones below walks the cost's components, Parun.Engine.EffectZone
-- classifies one effect. Neither is a case on which ability this is, and this
-- function is not one either -- it asks the same question of both halves of the
-- rule's own sentence and conjoins every answer (EffectZone.conjoin).
--
-- CR 113.6m applies once per zone named, so an ability whose cost names one
-- zone and whose effect names another functions only in the first AND only in
-- the second: in neither. The scenario "CR 113.6m an ability whose cost and
-- effect name different zones functions in neither" proves it on Synthetic
-- Errant Courier.
--
-- ALL MODES, and every effect of each: CR 700.2 makes a modal ability's modes
-- alternatives, so a zone stated by any of them is a zone the ability can move
-- its object out of. No modal ability in the pool states one.
--
-- This is the ACTIVATED reading of a rule that says "an ability";
-- Parun.Engine.Event.Trigger.zonesFunctionedIn is the triggered one, and has only the
-- effect half to fold, CR 603.1 giving a triggered ability no cost.
--
-- CR 113.6m's "a previous part of its cost or effect specifies that the
-- object is put into that zone" clause needs no order-sensitivity here, and
-- gets none: it can cancel no answer this fold gives. CR 400.7 mints a fresh
-- id on every zone change, so a part that puts the object into a zone leaves
-- CR 113.7a's source nothing to move -- a later part has to name the ARRIVAL
-- instead (Parun.Engine.Binding.became, or a slot the move itself minted, as
-- Meandering Towershell's "exiled" is), and this caller gives
-- Parun.Engine.EffectZone the reserved source slot alone. So the conjunction
-- and the rule's order-sensitive reading agree on every ability that can be
-- written, and a card whose later part moved the reserved source slot out of a
-- zone an earlier part put it into is what would refute that; see #2501.
--
-- CR 113.6m's final sentence is read by the fold too, Parun.Engine.EffectZone's
-- ArmDelayedTrigger arm answering off the `delayed` map this carries. The one
-- card in data/cards/ whose ACTIVATED ability arms a delayed trigger is Grist,
-- the Hunger Tide, and what it arms destroys a target rather than moving Grist,
-- so the walk names no zone there. This reading is therefore a regression
-- fence; the sentence itself is proved through the TRIGGERED one, on Prized
-- Amalgam in Parun.ZoneTriggerSpec.
--
-- Ahead of both halves, CR 113.6b: a keyword whose rule names the zones its
-- ability functions from answers first (Keyword.statedZones) -- CR 702.57a's
-- forecast, and CR 702.49d's commander ninjutsu, the one that names two, which
-- is why this answers a set.
zonesFunctionedIn :: Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card) -> Maybe (Set.Set Zone.Zone)
zonesFunctionedIn delayed ability =
  case foldMap Keyword.statedZones (ActivatedAbility.keyword ability) of
    stated
      | not (Set.null stated) -> Just stated
      | otherwise ->
          EffectZone.conjoin $
            costZones (ActivatedAbility.cost ability)
              <> foldMap
                -- CR 113.7's source slot ALONE is "the object it's on" here: an
                -- activation is not an event, so Parun.Engine.Event.Binding.eventBindings
                -- never runs for one and CR 400.7e's `became` names nothing.
                (EffectZone.zonesFunctionedFrom (Set.singleton Binding.triggerSource) delayed)
                (Modal.allEffects (ActivatedAbility.modal ability))

-- CR 113.6m's "functions only in that zone", asked of one zone: does this
-- ability function from there? For an ability that names no zone at all, only
-- `home`: the battlefield, CR 113.6's default, or the command zone for an object
-- CR 113.6p names (Parun.Engine.Vanguard.homeZoneOf).
functionsIn :: Zone.Zone -> Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) -> Zone.Zone -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card) -> Bool
functionsIn home delayed zone ability = case zonesFunctionedIn delayed ability of
  Nothing -> zone == home
  Just named -> Set.member zone named

-- CR 113.6m's COST half: an ability whose cost moves the object it's on out of a
-- particular zone functions only in that zone. The "or effect" half is
-- Parun.Engine.EffectZone, and zonesFunctionedIn above conjoins them.
--
-- Every component's zone: empty when the cost names none, leaving the effect
-- half to answer and CR 113.6's battlefield default otherwise -- SacrificeThis'
-- answer too, CR 701.21a moving the object off the battlefield where CR 113.6
-- already had it. Two components naming different zones leave the ability
-- functioning nowhere, by the same conjunction.
costZones :: Cost Keyword.Type.Keyword -> Set.Set Zone.Zone
costZones cost = foldMap (foldMap Set.singleton . zoneOfComponent) (Cost.components cost)

zoneOfComponent :: CostComponent.CostComponent Keyword.Type.Keyword -> Maybe Zone.Zone
zoneOfComponent component = case component of
  -- CR 702.29a's "Discard this card": the hand, where cycling functions.
  -- LOAD-BEARING since CR 702.29b and CR 702.77b put the minted cycling and
  -- reinforce abilities into the projection for every zone -- this is what keeps
  -- a Rustic Clachan on the battlefield from offering its reinforce ability.
  CostComponent.DiscardThis _ -> Just Zone.Hand
  CostComponent.ExileThisFromGraveyard -> Just Zone.Graveyard
  CostComponent.TapThis -> Nothing
  CostComponent.UntapThis -> Nothing
  -- CR 113.6m again, and Nothing for SacrificeThis' reason above: it moves the
  -- object off the BATTLEFIELD, where CR 113.6's default already had it, so
  -- naming the zone would be redundant rather than wrong. A FENCE and not proven
  -- behaviour, for exactly that reason -- answering Just Zone.Battlefield leaves
  -- the suite green, the two readings agreeing wherever CR 113.6's default holds.
  CostComponent.ReturnThis -> Nothing
  CostComponent.SacrificeThis -> Nothing
  CostComponent.ExileThis -> Nothing
  CostComponent.PayLife _ -> Nothing
  CostComponent.PayHalfLife _ -> Nothing
  CostComponent.Sacrifice {} -> Nothing
  -- These tap permanents that stay on the battlefield, so nothing moves out of
  -- any zone and CR 113.6's default stands.
  CostComponent.TapForTotalPower {} -> Nothing
  CostComponent.TapPermanents {} -> Nothing
  -- Nothing, and NOT Just Zone.Battlefield: CR 113.6m is about an ability that
  -- moves THE OBJECT IT'S ON, and this moves OTHER permanents.
  CostComponent.ReturnPermanents {} -> Nothing
  CostComponent.ExilePermanents {} -> Nothing
  -- Nothing, and NOT Just Zone.Graveyard: rule 113.6m again, and these move
  -- OTHER cards.
  CostComponent.ExileCardsFromGraveyard {} -> Nothing
  CostComponent.ExileTopFromGraveyard _ -> Nothing
  CostComponent.CollectEvidence _ -> Nothing
  CostComponent.CollectEvidenceOfTargets -> Nothing
  -- Nothing for the arms above's reason and one more: CR 702.167a's component
  -- moves objects out of TWO zones, so there is no single zone to name even if
  -- rule 113.6m asked about them.
  CostComponent.ExileMaterials {} -> Nothing
  CostComponent.DiscardCards {} -> Nothing
  -- Nothing, and NOT Just Zone.Hand as DiscardThis above answers, for the same
  -- reason the arms above give: CR 113.6m asks about an ability that moves THE
  -- OBJECT IT'S ON, and these move another card out of the payer's hand.
  CostComponent.PutCardFromHandOntoBattlefield _ -> Nothing
  CostComponent.ExileCardsFromHand {} -> Nothing
  -- Nothing for a further reason than the arms above: CR 701.20b moves no card
  -- at all, so there is no zone for CR 113.6m to be told about.
  CostComponent.RevealCardFromHand _ -> Nothing
  -- Nothing, the arm above's reason: CR 701.4a moves no object at all, whichever
  -- of its two halves the payer takes, so there is no zone for CR 113.6m to be
  -- told about.
  CostComponent.Behold _ -> Nothing
  -- Nothing, and NOT Just Zone.Hand or Zone.Battlefield: CR 113.6m asks about an
  -- ability that moves THE OBJECT IT'S ON, and this exiles another object.
  CostComponent.BeholdAndExile _ -> Nothing
  -- Nothing, and NOT Just Zone.Library, for the arms above's reason: CR 701.17a
  -- mills the cards on top of the paying player's library, which are OTHER cards
  -- than the object the cost is on -- a Millikin on the battlefield is not in the
  -- library it mills.
  CostComponent.MillCards _ -> Nothing
  CostComponent.RevealTopOfLibrary _ -> Nothing
  CostComponent.PayEnergy _ -> Nothing
  CostComponent.AddLoyaltyToThis _ -> Nothing
  CostComponent.RemoveLoyaltyFromThis _ -> Nothing
  -- CR 122.1's counter is a marker and not an object, and CR 122.2 has counters
  -- "simply cease to exist" rather than travel, so removing one moves nothing out
  -- of any zone and CR 113.6's battlefield default stands. A FENCE and not proven
  -- behaviour, as ReturnThis' answer above is: Barkhide Troll's ability functions
  -- on the battlefield under either answer, so nothing separates them.
  CostComponent.RemoveCountersFromThis _ -> Nothing
  -- Nothing for the arm above's reason and one more: the counters come off
  -- ANOTHER permanent, which CR 113.6m does not ask about either way.
  CostComponent.RemoveCounters {} -> Nothing
  -- CR 122.6 puts counters on a permanent already where it is, so nothing moves
  -- out of any zone.
  CostComponent.PutCountersOnThis _ -> Nothing
  CostComponent.Blight _ -> Nothing
  -- Nothing, and NOT Just Zone.Graveyard: rule 113.6m asks about an ability that
  -- moves THE OBJECT IT'S ON, and CR 701.61a moves OTHER cards -- the
  -- ExileCardsFromGraveyard arm above's answer, for its reason, and the Food half
  -- is Sacrifice's.
  CostComponent.Forage -> Nothing
  CostComponent.FlipCoin -> Nothing
  CostComponent.ChooseOpponent _ -> Nothing
  CostComponent.Waterbend _ -> Nothing
  CostComponent.WaterbendInstead _ -> Nothing

-- CR 113.6 / 604.2 / 702.178b: does the "as long as" grant that gives an object
-- this ability function where the object is? A grant is a static ability, so
-- in `home` (functionsIn's: CR 113.6's battlefield default, or CR 113.6p's
-- command zone), and also in any zone the granted ability states (CR 113.6b /
-- 113.6m), which CR 702.178b makes the grant's too.
-- Loxodon Surveyor's ruling says "too": its max speed ability functions on the
-- battlefield as well as in the graveyard. True for an ability no grant gives
-- (no condition): the object simply has it, in every zone. Parun.ActivateSpec's
-- Villainous Ogre craft cases prove the off-battlefield half.
--
-- CR 702.178b is max speed's rule and parun reads every grant by it: a printed
-- "as long as" grant of an ability that states a zone would test the
-- difference. Scryfall `o:/as long as .*, (this|~) has "/ o:graveyard -o:"max
-- speed"`, 2026-10-15: every hit is a threshold grant of a triggered ability or
-- of a battlefield one.
--
-- The command-zone half is proved by data/scenarios/vanguard's
-- Synthetic Steward Avatar pair.
grantFunctionsIn :: Zone.Zone -> Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) -> Zone.Zone -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card) -> Bool
grantFunctionsIn home delayed zone ability = case ActivatedAbility.condition ability of
  Nothing -> True
  Just _ -> zone == home || functionsIn home delayed zone ability
