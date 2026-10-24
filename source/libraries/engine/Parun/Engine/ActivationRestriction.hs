-- CR 602.5: the reader of Parun.Types.ActivationRestriction -- does every clause
-- of an ability's printed "activate only ..." rider permit activating it right
-- now?
--
-- ITS OWN module, below Parun.Engine.Cost, because CR 605.3a's windows are served
-- from there: Parun.Engine.Activate refuses a mana ability outright (CR 605.3b),
-- so a rider printed on one is asked at Cost.manaActivations instead, and that
-- module cannot import Parun.Engine.Activate. Every window an arm reads is
-- Parun.Engine.Turn's for the same reason:
-- Parun.Engine.Combat imports Parun.Engine.Cost, so the two combat-record readers
-- CR 506.7g and CR 508.3b share with the casting side moved down to
-- Parun.Engine.Turn, beside the other two windows these arms ask about.
-- Two arms read no window at all: CR 602.5's board condition, which imports
-- Parun.Engine.Condition and Parun.Engine.Projection, neither of which reaches back
-- here, and CR 602.5b's two counted riders, which read what this source has
-- already activated -- for the whole game, off the object, and for this turn,
-- off GameState.activatedThisTurn.
--
-- The only module that may CASE on Parun.Types.ActivationRestriction, exactly as
-- Parun.Engine.CombatRestriction is of the type it names. Casing on the arms is a
-- classification, not an effect's identity.
module Parun.Engine.ActivationRestriction where

import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Condition as Condition
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Chosen as Chosen
import qualified Parun.Types.DuringPhase as DuringPhase
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.PastActivation as PastActivation
import Parun.Types.PlayerId (PlayerId)

-- CR 602.5: does every clause of this ability's printed "activate only ..."
-- rider permit activating it right now?
--
-- ALL of them, which is what CR 602.5's "prohibited from being activated" means:
-- one clause failing is a prohibition in force, and a card printing two joins
-- them with "and". The empty list leaves the ability whatever window the rules
-- already give it -- CR 602.2's priority, CR 605.3a's two for a mana ability --
-- and passes vacuously.
--
-- Priority is not re-checked here. Parun.Engine.Activate's caller is
-- Action.legalActions, which the priority loop asks only of the player who has
-- priority; Cost.manaActivations' two windows are CR 605.3a's, which is a
-- PERMISSION to activate outside priority rather than a fourth conjunct.
--
-- CASTING PROHIBITIONS ARE NOT CONSULTED, by any clause. CR 307.5 says so for the
-- sorcery-speed rider, and no rule extends Parun.Engine.Cast's CR 601.3 list to
-- an activation either, since CR 601.3 is about beginning to CAST a spell. That
-- is why this reads the game state directly rather than reaching for
-- Parun.Types.CastingRestriction, whose arms are spelled the same way and answer
-- a different question.
--
-- This gate makes the ability un-OFFERED, and Engine.priorityLoop is what makes
-- that binding: it rejects an action the interpreter was not offered (#219). On
-- the mana path it also makes the source unpayable, Cost.manaActivations being
-- asked at both of CR 605.3a's windows.
--
-- THE ABILITY rides along beside its restrictions because CR 602.5b's counted
-- rider is about the ability and not only about the object: OnlyOnce asks which
-- ability of this source has been spent, and the source may hold two. Both
-- callers have one -- Parun.Engine.Activate off the ability it is activating, and
-- CR 605.3a's mana window off Parun.Types.ManaOption, which carries it for this.
-- Nothing is CR 305.6's intrinsic route, which is printed on no card and prints
-- no rider, so no arm here can be asked of it.
restrictionsOk :: PlayerId -> ObjectId -> Maybe (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) -> [ActivationRestriction.ActivationRestriction] -> GameState -> Bool
restrictionsOk pid srcId ability restrictions gs = all (restrictionMet pid srcId ability gs) restrictions

-- Does the game state satisfy this one printed clause?
--
-- The SOURCE's id rides along for the OnlyIf arm and both counted ones: CR
-- 602.5's board condition is a Parun.Types.Condition, and
-- Parun.Engine.Condition.holds evaluates every Quantity in one against an object,
-- while CR 602.5b's two counted riders are keyed to it. Every other arm reads a
-- phase, a turn or the combat record and ignores it.
restrictionMet :: PlayerId -> ObjectId -> Maybe (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) -> GameState -> ActivationRestriction.ActivationRestriction -> Bool
restrictionMet pid srcId ability gs restriction = case restriction of
  -- CR 307.5's three conjuncts, and Turn.sorcerySpeedWindow is that window shared
  -- with CR 307.1's casting gate: two rules, the same three facts, one copy.
  --
  -- CR 307.5's empty-stack conjunct is the one window that can change under a
  -- payer between the offer and the payment, since CR 601.2a and CR 602.2a both
  -- put an object on the stack in between. `needsEmptyStack` below is how the two
  -- gates one step ahead of that move ask about it, and Grinning Ignus is the
  -- printing that lands on it.
  ActivationRestriction.SorcerySpeed -> Turn.sorcerySpeedWindow pid gs
  -- CR 500.1's phases and steps: Turn.inWindow asks whether GameState.phase
  -- falls inside the window the rider names. CONTAINMENT rather than equality,
  -- because a rider may name a phase that has steps -- Jade Statue's "only
  -- during combat" is live in all five of CR 506.1's combat steps, while
  -- Desert's names one of them. Parun.Engine.Cast reads the same
  -- Parun.Types.DuringPhase bundle off CastingRestriction.DuringPhase;
  -- deliberately duplicated rather than shared, since the two gates differ in
  -- what else they may read.
  --
  -- CR 102.1 supplies the second conjunct, a genuinely separate fact: Desert's
  -- rider names no turn (EachTurn, and the step alone decides), while Llanowar
  -- Augur's "only during your upkeep" names alice's upkeep and not bob's. CR
  -- 109.5 is why `pid` answers "your" -- for an activated ability that is the
  -- player who activated it, which Activatable.activatable has already pinned to
  -- activatorOf and which CR 109.4a and CR 113.8 make the activating player for
  -- a mana ability too -- so a stolen permanent's rider follows the thief, and
  -- Mana Cache's "their turn" follows whoever activates it.
  ActivationRestriction.DuringPhase (DuringPhase.MkDuringPhase window scope) ->
    Turn.inWindow window (GameState.phase gs)
      && Turn.turnScopeAdmits gs scope (GameState.activePlayer gs) pid
  -- CR 102.1 alone, with no window beside it: the rider names a turn and every
  -- phase and step of that turn is inside it. The same second conjunct
  -- DuringPhase reads above, standing on its own -- so this is not DuringPhase
  -- with a wildcard window but the absence of that axis.
  ActivationRestriction.DuringTurn scope ->
    Turn.turnScopeAdmits gs scope (GameState.activePlayer gs) pid
  -- CR 508.3b's question, asked of the ACTIVATING player, and the same reader the
  -- casting side's clause of this name uses -- see Turn.attackedThisStep for
  -- why it is the declaration record and not Combat.attacked.
  ActivationRestriction.AttackedThisStep -> Turn.attackedThisStep pid gs
  -- CR 506.7b through CR 506.7g, which says an "activate only" rider naming one
  -- of CR 506.7's points is governed exactly as the same words on a cast are --
  -- so this is Turn.afterBlockersDeclared verbatim, the reader Parun.Engine.Cast's arm
  -- of this name uses. Trap Runner is the card.
  ActivationRestriction.AfterBlockersDeclared -> Turn.afterBlockersDeclared gs
  -- CR 506.7 through CR 506.7g, the same extension to abilities that governs
  -- AfterBlockersDeclared above. Turn.beforeCombatDamage reads the phase rather
  -- than the combat record, since CR 510.2's damage is a turn-based action of one
  -- step and CR 506.7c admits every combat phase of the turn. Save Point.
  ActivationRestriction.BeforeCombatDamage -> Turn.beforeCombatDamage (GameState.phase gs)
  -- CR 506.7a, 506.7d and 506.7e through CR 506.7g; Turn.beforeStep says why it
  -- reads the turn's log. Capricious Sorcerer and Mana Cache.
  ActivationRestriction.BeforeStep target -> Turn.beforeStep target gs
  -- CR 602.5's prohibition over a fact about the board rather than a window:
  -- Barbarian Ring's "Activate only if there are seven or more cards in your
  -- graveyard". Projection.fullView because nothing here is inside a layer fold
  -- and no object is missing -- Parun.Engine.Activatable.zoneAbilitiesOf takes the
  -- same view for ActivatedAbility.condition, for the same reason.
  --
  -- CR 109.5's "your" is `pid`, the same player every arm above answers "your"
  -- with, and CR 109.4a makes it the activating player on the mana path.
  --
  -- Nimbus Maze is the producer on that path -- "{T}: Add {W}. Activate only if
  -- you control an Island" -- and Parun.ManaSpec's Nimbus Maze group is what proves
  -- this arm gates both of CR 605.3a's windows.
  --
  -- Read against the board AFTER CR 601.2a's move (Game.withoutBeingCast): a
  -- cast gate asks this one step ahead of it, and the payment asks it after, so
  -- a condition over the zone the card leaves answers the same at both.
  -- data/scenarios/mana's Lys Alana Dignitary cases prove the refused offer and
  -- its Synthetic Hollow Spring cases the admitted one.
  ActivationRestriction.OnlyIf condition ->
    let moved = Game.withoutBeingCast gs
     in Condition.holds
          (Projection.fullView moved)
          (Projection.sourceContext moved (Just pid) srcId)
          moved
          srcId
          condition
  -- CR 602.5b's counted rider, one of the two arms that read neither a window nor
  -- the board: has THIS ability of THIS object already been activated, EVER? CR 400.7
  -- ends the memory with the incarnation (Object.newIncarnation), so a permanent
  -- that leaves and returns answers True again -- Parun.ActivateSpec's "CR 400.7 /
  -- 602.5b the permanent that returns may activate it again" is what proves it.
  --
  -- An object that is GONE answers True: CR 602.5b's restriction is a fact about
  -- an object, and Activatable.activatable has already required this one to be
  -- somewhere it offers abilities from.
  --
  -- CR 605.3a's mana window asks this too, off the ability
  -- Parun.Engine.Mana.manaRoutesOfGiven carries onto the route -- Loot, the
  -- Pathfinder's "{G}, {T}: Add three mana of any one color", which
  -- data/scenarios/mana's Loot boards prove. Nothing is CR 305.6's intrinsic
  -- route alone, which prints no rider, so the answer below is unreachable rather
  -- than a claim about one.
  ActivationRestriction.OnlyOnce -> case ability of
    Nothing -> False
    Just this -> case Game.lookupObject srcId gs of
      Nothing -> True
      Just object -> unspent srcId this (Object.activatedOnce object) gs
  -- CR 602.5b's own example, the same question asked of THIS TURN: has this
  -- ability of this object been activated since the turn began? The record is
  -- GameState.activatedThisTurn, which Engine.beginTurnOf clears -- so the reset
  -- is the turn handoff itself and nothing on the object survives it.
  --
  -- Nothing is CR 305.6's intrinsic route, which prints no rider, exactly as
  -- OnlyOnce above. No object is looked up: the record is keyed by the id, so a
  -- source that has left keeps whatever it spent until the turn ends, and
  -- Activatable.activatable has already required the source of an OFFER to be
  -- somewhere it offers abilities from.
  ActivationRestriction.OnlyOnceEachTurn -> case ability of
    Nothing -> False
    Just this -> unspent srcId this (Map.findWithDefault Map.empty srcId (GameState.activatedThisTurn gs)) gs
  -- Goblin Bookie's "any time it makes sense", read as CR 706.2's modification
  -- step: open only while Parun.Engine.Resolve.Effect.throwDice is asking
  -- about a die, so never at priority (CR 117.1b).
  ActivationRestriction.DuringDieRoll -> Maybe.isJust (GameState.rollingDie gs)
  -- A payment rule, not a gate: Parun.Engine.Mana.admitsUnder spends only the
  -- mana it names (PaymentSubject.Activating's colours).
  ActivationRestriction.SpendOnly _ -> True
  -- CR 602.5e: the timing of an instant, which CR 304.5 reduces to holding
  -- priority. Every road that asks this board-reading gate is one where the
  -- activator holds it -- Engine.priorityLoop's offer, Activate.activateAbility
  -- -- and the payment windows CR 605.3a adds for a mana ability refuse the
  -- route before asking (`refusedMidPayment`), since no board fact tells a
  -- payment in progress apart.
  ActivationRestriction.InstantSpeed -> True

-- CR 602.5d under a permission to activate "any time you could cast an instant"
-- (Leonin Shikari): the sorcery-speed rider reads as CR 602.5e's instant-speed
-- one, and every other clause stands -- "You're still subject to any other
-- restrictions", per the Shikari's ruling. Exhaustive, so a new timing clause
-- is named here by -Werror.
atInstantSpeed :: ActivationRestriction.ActivationRestriction -> ActivationRestriction.ActivationRestriction
atInstantSpeed restriction = case restriction of
  ActivationRestriction.SorcerySpeed -> ActivationRestriction.InstantSpeed
  ActivationRestriction.DuringPhase _ -> restriction
  ActivationRestriction.DuringTurn _ -> restriction
  ActivationRestriction.AttackedThisStep -> restriction
  ActivationRestriction.AfterBlockersDeclared -> restriction
  ActivationRestriction.BeforeCombatDamage -> restriction
  ActivationRestriction.BeforeStep _ -> restriction
  ActivationRestriction.OnlyIf _ -> restriction
  ActivationRestriction.OnlyOnce -> restriction
  ActivationRestriction.OnlyOnceEachTurn -> restriction
  ActivationRestriction.DuringDieRoll -> restriction
  ActivationRestriction.SpendOnly _ -> restriction
  ActivationRestriction.InstantSpeed -> restriction

-- CR 602.5b / 602.5c: does `srcId` bear a copy of `this` not yet spent? Each
-- identically worded copy (CR 113.2c) is its own ability to a restriction on
-- its use, so the counted spends are compared with the copies the source now
-- bears. At least one copy, so an ability no projection lists (a rule-702
-- minted one, off the battlefield) keeps the plain "not yet" reading. The
-- projection is asked only once something is spent.
--
-- Not implemented: the count cannot say WHICH copy spent, so when the spent
-- copy's grant goes and an unspent twin stays, the twin reads as spent (#4627).
--
-- Parun.ActivateSpec's "CR 602.5c two Gliding Licids give the Locus two
-- once-each-turn animate abilities" proves the per-turn record. The count is
-- a REGRESSION FENCE: abilities acquired from two exiled cards are unequal
-- (Binding.exiledCardAbility), so only two equal grants of one ability
-- printing the rider reach it -- two Auras quoting one. No card in
-- data/cards/ carries both an OnlyOnce rider and a GainAbility (grep,
-- 2026-10-19).
unspent :: ObjectId -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card) -> Map.Map (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) Natural -> GameState -> Bool
unspent srcId this spent gs = case Map.findWithDefault 0 this spent of
  0 -> True
  n -> n < max 1 (List.genericLength (filter (== this) (Projection.abilitiesOf srcId gs)))

-- CR 602.5b: record that THIS ability of this source has now been activated,
-- for whichever counted rider it prints. The writer both readers above are
-- served from, so the two roads to an activation cannot disagree:
-- Parun.Engine.Activate.activateAbility for an ability CR 602.2a puts on the
-- stack, and Parun.Engine.Cost.tapForManaWith for one CR 605.3b keeps off it.
--
-- Only for an ability that PRINTS the rider, so nothing else grows either store,
-- and only after the payment was made -- every rejecting path restores the state
-- it started from, so no refused activation leaves a record behind.
--
-- The per-GAME store is on the source object, which CR 602.5b names ("continues
-- to apply to that object") and CR 400.7 then forgets for free; Map.adjust is a
-- no-op when the cost sacrificed it, and that is right. The per-TURN store is
-- GameState.activatedThisTurn, cleared at the handoff (Engine.beginTurnOf), and
-- an entry for a source the cost sacrificed is kept rather than dropped: object
-- ids are not reused, so it can name nothing else before the turn ends.
recordActivation :: ObjectId -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card) -> GameState -> GameState
recordActivation srcId ability gs =
  let prints restriction = elem restriction (Keyword.restrictionsOf ability)
      perGame g =
        g {GameState.objects = Map.adjust (\o -> o {Object.activatedOnce = Map.insertWith (+) ability 1 (Object.activatedOnce o)}) srcId (GameState.objects g)}
      perTurn g =
        g {GameState.activatedThisTurn = Map.insertWith (Map.unionWith (+)) srcId (Map.singleton ability 1) (GameState.activatedThisTurn g)}
   in (if prints ActivationRestriction.OnlyOnceEachTurn then perTurn else id)
        ((if prints ActivationRestriction.OnlyOnce then perGame else id) gs)

-- CR 602.2: log that `pid` began activating an ability of `srcId` aimed at
-- `targets`, for Parun.Types.CostModifier.onlyFirst to count. The source
-- and targets are snapshotted off `asOf`, the board the activation began on, so
-- a cost that sacrificed the source still leaves it recorded as it was.
--
-- Every activation, of every kind, from all three roads: Parun.Engine.Activate's
-- stack ability, Parun.Engine.Cost's mana ability and Parun.Engine.Resolve.Effect's
-- mid-roll one. The latter two are a regression fence: Professor Hojo, the one
-- first-limited reducer in data/cards/, names a target, which neither road's
-- abilities have. Tezzeret, Betrayer of Flesh would observe the mana road.
logActivation :: GameState -> PlayerId -> ObjectId -> Maybe Keyword.Type.Keyword -> AbilityKind.AbilityKind -> Set.Set ObjectId -> GameState -> GameState
logActivation asOf pid srcId stamp kind targets gs =
  let logged source =
        PastActivation.MkPastActivation
          { PastActivation.activator = pid,
            PastActivation.source = source,
            PastActivation.keyword = stamp,
            PastActivation.kind = kind,
            PastActivation.targets = Maybe.mapMaybe (\oid -> Projection.objectSnapshot oid asOf) (Set.toList targets)
          }
   in case Projection.objectSnapshot srcId asOf of
        Nothing -> gs
        Just source -> gs {GameState.activationsThisTurn = GameState.activationsThisTurn gs Seq.|> logged source}

-- CR 307.5's empty-stack conjunct asked ABOUT THE RIDER rather than about the
-- board: does this clause need an empty stack to be met?
--
-- What wants it is a gate asked one step AHEAD of a payment. CR 601.2a puts the
-- spell on the stack and CR 602.2a the ability, both BEFORE CR 601.2f-h totals
-- and pays the cost, so no such payment ever has an empty stack -- and a gate
-- reading GameState.stack would read the stack of the wrong moment and count a
-- source the payment cannot use (#2005). Parun.Engine.Cost.stackedManaActivations
-- is the one caller; `restrictionMet` above is what asks the board at the payment
-- itself, and the two agree because the move between them is exactly the fact
-- this reports.
--
-- SorcerySpeed alone, and the window arms are not a default: each of them reads
-- a phase, a turn, the steps begun this turn or a combat record, and CR 500.12
-- puts no game event between the gate and the payment while CR 601.2a's move
-- changes no phase and begins no step -- so their two windows agree already
-- (riderWindowSpec's pair in Parun.ManaSpec is that argument for the phase axis).
-- The arms below that read no window say for themselves why each answers False
-- without that argument.
needsEmptyStack :: ActivationRestriction.ActivationRestriction -> Bool
needsEmptyStack restriction = case restriction of
  ActivationRestriction.SorcerySpeed -> True
  ActivationRestriction.DuringPhase _ -> False
  ActivationRestriction.DuringTurn _ -> False
  ActivationRestriction.AttackedThisStep -> False
  ActivationRestriction.AfterBlockersDeclared -> False
  ActivationRestriction.BeforeCombatDamage -> False
  ActivationRestriction.BeforeStep _ -> False
  -- A board condition reads no stack, so the empty-stack question is not its
  -- question. What CR 601.2a's move does to the zone the card leaves,
  -- `restrictionMet` reads for itself (Game.withoutBeingCast).
  ActivationRestriction.OnlyIf _ -> False
  -- A record of past activations reads no stack either, and CR 601.2a's and CR
  -- 602.2a's move cannot write one: nothing is spent until the payment
  -- `restrictionsOk` gates.
  ActivationRestriction.OnlyOnce -> False
  -- The same record, timed per turn, and the same argument: CR 601.2a's and CR
  -- 602.2a's move ends no turn and spends no activation.
  ActivationRestriction.OnlyOnceEachTurn -> False
  -- A die roll's modification step opens inside a resolution, never at a
  -- payment's gate, so no move between the two can close it.
  ActivationRestriction.DuringDieRoll -> False
  ActivationRestriction.SpendOnly _ -> False
  -- Not a stack question: `refusedMidPayment` is how the payment windows ask.
  ActivationRestriction.InstantSpeed -> False

-- CR 602.5e / 605.3a: may a mana ability with this rider NOT be activated inside
-- a payment? "Activate only as an instant" keeps it to the priority window, so a
-- source whose route prints it is no source while a spell is being cast, an
-- ability activated, or a resolution cost paid (Rhystic Cave's ruling).
--
-- A classification, needsEmptyStack's posture: Parun.Engine.Cost asks it of the
-- rider at both of a payment's gates -- the supply the offer counts
-- (Cost.stackedManaActivations) and the window itself (Cost.midPayment) --
-- because nothing on the board says a payment is in progress.
refusedMidPayment :: ActivationRestriction.ActivationRestriction -> Bool
refusedMidPayment restriction = case restriction of
  ActivationRestriction.InstantSpeed -> True
  ActivationRestriction.SorcerySpeed -> False
  ActivationRestriction.DuringPhase _ -> False
  ActivationRestriction.DuringTurn _ -> False
  ActivationRestriction.AttackedThisStep -> False
  ActivationRestriction.AfterBlockersDeclared -> False
  ActivationRestriction.BeforeCombatDamage -> False
  ActivationRestriction.BeforeStep _ -> False
  ActivationRestriction.OnlyIf _ -> False
  ActivationRestriction.OnlyOnce -> False
  ActivationRestriction.OnlyOnceEachTurn -> False
  ActivationRestriction.DuringDieRoll -> False
  ActivationRestriction.SpendOnly _ -> False

-- The mana types an activation under these restrictions may spend, Nothing for
-- any (PaymentSubject.Activating): SpendOnly's chosen colours are the source's
-- (CR 607.2d), read through CR 608.2h's last known information.
spendableTypes :: ObjectId -> [ActivationRestriction.ActivationRestriction] -> GameState -> Maybe (Set.Set ManaType.ManaType)
spendableTypes srcId restrictions gs =
  let named restriction = case restriction of
        ActivationRestriction.SpendOnly ManaSpecification.ChosenColor -> Just (Set.map ManaType.Colored (Maybe.fromMaybe Set.empty (Game.choiceWithLastKnown Chosen.Colors (Game.acquisitionOf srcId gs) srcId gs)))
        ActivationRestriction.SpendOnly (ManaSpecification.OfColor color) -> Just (Set.singleton (ManaType.Colored color))
        ActivationRestriction.SpendOnly ManaSpecification.AnyMana -> Nothing
        -- The rest time or count an activation and say nothing of its mana.
        _ -> Nothing
   in case Maybe.mapMaybe named restrictions of
        [] -> Nothing
        first : rest -> Just (List.foldl' Set.intersection first rest)
