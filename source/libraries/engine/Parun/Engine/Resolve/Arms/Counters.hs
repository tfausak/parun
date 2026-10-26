-- applyOneEffect's arms from counter to takeExtraTurnArm, one function per
-- Effect constructor, cut from Parun.Engine.Resolve.Effect along its order so the
-- arms compile in parallel. Each takes the resolution parameters its body reads,
-- then the constructor's fields.
module Parun.Engine.Resolve.Arms.Counters where

import Control.Applicative ((<|>))
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Parun.Engine.Airbend as Airbend
import qualified Parun.Engine.Amass as Amass
import qualified Parun.Engine.Archenemy as Archenemy
import qualified Parun.Engine.Attraction as Attraction
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Blight as Blight
import qualified Parun.Engine.Cloak as Cloak
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Contraption as Contraption
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.CounterRestriction as CounterRestriction
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Departure as Departure
import qualified Parun.Engine.Detain as Detain
import qualified Parun.Engine.Dungeon as Dungeon
import qualified Parun.Engine.Earthbend as Earthbend
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Expiry as Expiry
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Forage as Forage
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Goad as Goad
import qualified Parun.Engine.Learn as Learn
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.ManifestDread as ManifestDread
import qualified Parun.Engine.Phasing as Phasing
import qualified Parun.Engine.Planechase as Planechase
import qualified Parun.Engine.Populate as Populate
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Recruit as Recruit
import qualified Parun.Engine.Replacement as Replacement
import Parun.Engine.Resolve.Common (apnapDecidersOf, askedChooser, askingObjects, bindAmountSlot, bindEarthbentLand, bindObjects, bindObjectsSlot, bindSlot, carrying, distributes, evaluateForRecipient, exileOrCease, installControl, movableCounters, movablePair, objectRefRecipients, overHolderBindings, proliferateOnce, removableAmong, turnPermanentsOver)
import {-# SOURCE #-} Parun.Engine.Resolve.Effect (applyEffectWith, runDamageRewriteEffect, runReplacementEffects)
import Parun.Engine.Resolve.Slots (battlefieldMatching, effectContext, effectViewOf, legalOne, objectRefObjects, playerRefPlayers, slotBindings)
import qualified Parun.Engine.Ring as Ring
import qualified Parun.Engine.Sba as Sba
import qualified Parun.Engine.Soulbond as Soulbond
import qualified Parun.Engine.TimeTravel as TimeTravel
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Amass as Amass.Type
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.Blight as Blight.Type
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.ChooseCardName as ChooseCardName
import qualified Parun.Types.ChooseNumber as ChooseNumber
import qualified Parun.Types.Chosen as Chosen
import qualified Parun.Types.ChosenQuality as ChosenQuality
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.ControlSides as ControlSides
import qualified Parun.Types.ControlSlots as ControlSlots
import qualified Parun.Types.Counter as Counter
import qualified Parun.Types.CounterCause as CounterCause
import qualified Parun.Types.CounterDestination as CounterDestination
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterKindFor as CounterKindFor
import qualified Parun.Types.CounterSpread as CounterSpread
import qualified Parun.Types.CounteredEnd as CounteredEnd
import qualified Parun.Types.Divide as Divide
import qualified Parun.Types.DoesNotUntapNext as DoesNotUntapNext
import qualified Parun.Types.Earthbend as Earthbend.Type
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EndTurnSignal as EndTurnSignal
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Expiry as Expiry.Type
import qualified Parun.Types.ExtraPhase as ExtraPhase
import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.GainControl as GainControl
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.Meld as Meld
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.MoveCounters as MoveCounters
import qualified Parun.Types.MoveSpread as MoveSpread
import qualified Parun.Types.MovedKinds as MovedKinds
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ObjectRef (ObjectRef)
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlaneswalkCause as PlaneswalkCause
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerCounters as PlayerCounters
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerInstruction as PlayerInstruction
import Parun.Types.PlayerRef (PlayerRef)
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.ProposedEvent as ProposedEvent
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.PutCountersFrom as PutCountersFrom
import qualified Parun.Types.Quantity as Quantity.Type
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.RemovalCount as RemovalCount
import qualified Parun.Types.RemoveCounters as RemoveCounters
import qualified Parun.Types.RemoveCountersAmong as RemoveCountersAmong
import qualified Parun.Types.RemovePlayerCounters as RemovePlayerCounters
import Parun.Types.Result (Result)
import qualified Parun.Types.Sickness as Sickness
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.Source as Source
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TakeExtraTurn as TakeExtraTurn
import qualified Parun.Types.Tap as Tap
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.WhichCounters as WhichCounters
import qualified Parun.Types.Zone as Zone

counter :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Counter.Counter -> Game ()
counter resolving source controller legal (Counter.MkCounter ref mSlot mSources mInstead) = do
  gs <- State.get
  let named = objectRefObjects legal resolving controller source gs ref
      -- CR 113.7: each named ability's source, read BEFORE the funnel runs --
      -- CR 608.2n makes a countered ability cease, so afterwards there is no
      -- object left to walk from.
      sourceOf = Map.fromList (Maybe.mapMaybe (\oid -> fmap ((,) oid) (Game.abilitySourceOf oid gs)) named)
  -- CR 701.6a: counter each named object through the single funnel, which picks
  -- that rule's ending from each object's own kind. A player recipient or an
  -- illegal target (CR 608.2b) counters nothing. The whole set goes as ONE
  -- batch (CR 608.2f).
  --
  -- The funnel is handed THIS effect's source and controller, which Baral,
  -- Chief of Compliance reads off the event: by the CR 117.5 trigger scan the
  -- controller can no longer be asked for exactly (see Parun.Types.Countering).
  --
  -- Delay's "exile it ... instead", Remand's hand, Desertion's battlefield:
  -- a self-replacement effect (CR 614.15), which CR 616.1a applies before any
  -- other, so it is folded into the destination and the funnel offers the
  -- rest the replaced move -- Delay's ruling (2021-03-19) has it exile a spell
  -- cast with flashback, "not the flashback effect".
  --
  -- Decided per spell off the board BEFORE the funnel (CR 608.2f), against
  -- the spell as it stands on the stack: Desertion's "if an artifact or
  -- creature spell is countered this way". A copy of a spell is no card, so
  -- Desertion's "put that card" has nothing to move and the copy takes CR
  -- 701.6a's ending, where CR 704.5e ends it; for the other destinations the
  -- copy ceases wherever it lands, so the reading is the same.
  let context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      viewOf = effectViewOf source legal gs
      isCard oid = case fmap Object.source (Game.lookupObject oid gs) of
        Just (Source.OfCard _) -> True
        _ -> False
      applies destination oid = isCard oid && maybe True (\only -> maybe False (\view -> Filter.matches context view only) (viewOf oid)) (CounterDestination.only destination)
      -- Hinder's "your choice of the top or bottom": the countering spell's
      -- controller is asked (CR 401.2's end), and only once the funnel has
      -- passed the can't-be-countered gates, so a spell that is not
      -- countered asks nobody.
      destinationOf oid = case mInstead of
        Just destination | applies destination oid -> case CounterDestination.position destination of
          CounteredEnd.Stated position -> pure (CounterDestination.zone destination, position)
          CounteredEnd.CounteringPlayerChooses
            | CounterDestination.zone destination == Zone.Library -> do
                g <- State.get
                position <- Game.choose (Prompt.ChooseLibraryEnd (Decide.deciderFor controller g) controller oid 0)
                pure (Zone.Library, position)
            | otherwise -> pure (CounterDestination.zone destination, LibraryPosition.defaultValue)
        _ -> pure (Zone.Graveyard, LibraryPosition.defaultValue)
  moved <- Event.counterReturning destinationOf resolving source controller named
  let countered = fmap fst moved
  -- CR 701.6a's "countered this way" is what the funnel COUNTERED, never what
  -- the sweep named. Bound onto this effect's SOURCE, and bound even at zero.
  Monad.forM_ mSlot $ \slot ->
    State.modify' (bindAmountSlot resolving source slot (Natural.length countered))
  -- Delay's "exile it with three time counters on it": the cards the
  -- countering put into the destination, bound onto `resolving` as a GROUP,
  -- Destroy's `buried` shape and for its reason. Read off the board after the
  -- funnel, so a move a replacement sent elsewhere, or an entry CR 101.2
  -- refused, binds nothing; nothing is bound when nothing qualifies.
  Monad.forM_ mInstead $ \destination -> Monad.forM_ (CounterDestination.slot destination) $ \slot -> do
    after <- State.get
    let landed oid = fmap Object.zone (Game.lookupObject oid after) == Just (CounterDestination.zone destination)
        arrived = concatMap (filter landed . Foldable.toList . snd) moved
    Monad.unless (null arrived) (State.modify' (bindObjectsSlot resolving slot (Seq.fromList arrived)))
  -- CR 113.7: the PERMANENTS whose abilities the funnel countered, for Green
  -- Slime's "if a permanent's ability is countered this way, destroy that
  -- permanent". The funnel's answer walked to its sources, never the sweep's;
  -- a countered spell has no source. Read off the board AFTER the funnel, so a
  -- source that has left the battlefield -- sacrificed to activate the ability
  -- (CR 113.7a) -- is no permanent and is not bound. Bound onto `resolving` as a
  -- GROUP, Destroy's `permanents` shape and for its reason; nothing is bound
  -- when nothing qualifies, so the rider finds an unbound slot and does nothing.
  --
  -- The battlefield conjunct is the rule's word "permanent" and a REGRESSION
  -- FENCE rather than a proved behaviour: Event.destroy refuses a card in a
  -- graveyard on its own, so dropping the conjunct leaves the suite green
  -- (Parun.CounterspellSpec's Golden Egg case).
  Monad.forM_ mSources $ \slot -> do
    after <- State.get
    let permanents = Set.toList (Set.fromList (filter (\src -> Set.member src (GameState.battlefield after)) (Maybe.mapMaybe (\oid -> Map.lookup oid sourceOf) countered)))
    Monad.unless (null permanents) (State.modify' (bindObjectsSlot resolving slot (Seq.fromList permanents)))

putCounters :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> PutCounters.PutCounters -> Game ()
putCounters resolving source controller legal chosen (PutCounters.MkPutCounters kind quantity ref) = do
  -- CR 608.2c: the set is swept as this instruction is reached, and an
  -- illegal slot (CR 608.2b) or a player recipient answers with nobody. A
  -- CR 608.2d choice is asked through askingObjects, ModifyTarget's reason:
  -- Phylactery Lich's "put a phylactery counter on an artifact you control".
  targets <- askingObjects resolving source controller legal chosen ref
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- HOW MANY, read per recipient against the one pre-effect state, so a
      -- division's part (Quantity.Share, Effect.Divide's) is each member's
      -- own: DealDamage's amountFor. Every other quantity reads the same for
      -- every recipient, CR 608.2f's one evaluation for the whole set. An
      -- unevaluable or zero amount places nothing on that recipient.
      amountFor target =
        let sharing = context {Filter.shares = Binding.sharesOf (Recipient.ToObject target) (slotBindings resolving gs)}
         in Monad.mfilter (> 0) (Quantity.evaluateFor viewOf sharing gs resolving source quantity)
      placements = Maybe.mapMaybe (\target -> fmap ((,) target . Integer.toNaturalSaturating) (amountFor target)) targets
  -- CR 122.6's funnel per recipient, so CR 614's counter replacements apply
  -- against each placement.
  --
  -- ONE event for the PLACEMENTS, which is the Event.simultaneously
  -- bracket: CR 608.2f processes an action taken on multiple objects
  -- simultaneously, and one written instruction is one such action however
  -- many permanents the ref swept. CR 603.2c's batch conditions are what a
  -- board can read that with -- TriggerCondition.PermanentsGetCounters fires
  -- once for the sweep where its per-permanent twin fires once per recipient,
  -- and Parun.Engine.Event.Trigger.batchScoped is that fork.
  --
  -- The per-recipient CR 122.6 funnel below is no argument for N groups: CR
  -- 616.1g is where the rules say events nest at all -- a replacement may
  -- apply to "an event contained within the first event" -- so CR 614's
  -- per-placement replacement opportunity is not a second event. The swept
  -- Effect.MoveToZone arm (Parun.Engine.Resolve.Arms.Zones) runs the same shape, and Event.destroyIn a
  -- whole CR 616.1 loop, inside one bracket.
  --
  -- Only where something is placed, so an instruction placing no counters
  -- spends no group; and around the FOLD alone, the sweep above it having
  -- taken no action for CR 608.2f to be read over.
  Monad.unless (null placements) . Event.simultaneously . Monad.forM_ placements $ \(target, n) ->
    Event.putCounters (CounterCause.ByEffect controller) target kind n

-- CR 608.2d: the chooser picks which of the objects the ref names get a
-- part and how much, each chosen one at least one, the whole amount handed
-- out. Untargeted, so the set is swept as this instruction is reached (CR
-- 608.2c) and a permanent an earlier instruction tapped is in it (Crashing
-- Wave). Bound as a group carrying its division, so a later instruction
-- reads each member's part as Quantity.Share. One candidate leaves one
-- division, and is not asked; a zero amount, no candidate or no seat divides
-- nothing and binds nothing.
divide :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Divide.Divide -> Game ()
divide resolving source controller legal (Divide.MkDivide quantity among chooser slot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      candidates = ListUtils.nubOrd (objectRefObjects legal resolving controller source gs among)
  case (Quantity.evaluateFor viewOf context gs resolving source quantity, NonEmpty.nonEmpty candidates) of
    (Just n, Just offered) | n > 0 -> do
      asked <- askedChooser resolving source controller legal chooser
      Monad.forM_ asked $ \pid -> do
        let total = Integer.toNaturalSaturating n
            fallback = Map.singleton (NonEmpty.head offered) total
        division <- case offered of
          _ NonEmpty.:| [] -> pure fallback
          _ -> do
            now <- State.get
            answer <- Game.choose (Prompt.ChooseDistribution (Decide.deciderFor pid now) pid source total offered)
            -- An answer that does not divide the total among offered
            -- objects takes the replay default rather than a repair. A
            -- regression fence, not a proved behaviour: the scenario runner
            -- refuses an unoffered answer before it reaches here.
            pure (if distributes total offered answer then answer else fallback)
        let members = filter (`Map.member` division) candidates
            binding = (Binding.toObjects (Seq.fromList members)) {Binding.Type.division = Just (Map.mapKeys Recipient.ToObject division)}
        State.modify' (overHolderBindings resolving (Map.insert slot binding))
    _ -> pure ()

putCountersFrom :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PutCountersFrom.PutCountersFrom -> Game ()
putCountersFrom resolving source controller legal (PutCountersFrom.MkPutCountersFrom fromSlot kind ref) = do
  gs <- State.get
  -- CR 122.8: put the counters the `from` object HAD onto every permanent the
  -- ref names -- "the player puts the same number of each kind of counter the
  -- first object had onto the second object".
  --
  -- A PUT and nothing else: rule 122.8's first sentence says the player
  -- "doesn't move counters from one object to the other", so unlike the CR
  -- 122.5 arm below there is no removal, no atomicity to enforce and none of
  -- that rule's four impossibilities to check. CR 122.2 is why -- the first
  -- object's counters ceased to exist as it changed zones, and what rule 122.8
  -- reads is the tally, not the counters.
  --
  -- The tally comes off the VIEW rather than off Object.counters, which is what
  -- makes CR 608.2h answer it: `effectViewOf` hands the resolving SOURCE its
  -- last known information, and Iron Apprentice's "when this creature dies" is
  -- read off the source itself. A `from` slot naming a departing BYSTANDER is
  -- Binding.departedPermanent, which effectViewOf looks back for too --
  -- Resourceful Defense's "whenever a permanent you control leaves the
  -- battlefield", proved in Parun.PutCounterSpec.
  let viewOf = effectViewOf source legal gs
      -- CR 608.2c: the set is swept as this instruction is reached, and an
      -- illegal slot (CR 608.2b) or a player recipient answers with nobody.
      targets = objectRefObjects legal resolving controller source gs ref
      -- CR 122.8's second sentence: an ability that "specifies what kind(s) of
      -- counters to place" places "the same number of each of those kinds of
      -- counter the first object had", so a named kind narrows the tally to
      -- itself -- Selfless Police Captain's "put its +1/+1 counters", where
      -- Iron Apprentice's "put those counters" names none and takes all.
      narrow m = maybe m (Map.restrictKeys m . Set.singleton) kind
      -- Ascending (Map.toList), so a transcript is deterministic. A kind
      -- recorded at zero is dropped: it is not a kind the object HAD.
      tally = case legalOne fromSlot legal >>= Recipient.objectOf of
        Nothing -> Map.empty
        Just oid -> narrow (Map.filter (> 0) (maybe Map.empty Filter.counters (viewOf oid)))
  -- ONE event for the placements, the PutCounters arm's Event.simultaneously
  -- bracket and its reasons (CR 608.2f), spent only when something crosses.
  -- ONE call per kind per permanent inside it, which is CR 614.16's own unit.
  Monad.unless (Map.null tally) . Event.simultaneously . Monad.forM_ targets $ \target ->
    Monad.forM_ (Map.toList tally) (uncurry (Event.putCounters (CounterCause.ByEffect controller) target))

-- CR 201.4 via CR 608.2c: the players the PlayerRef names each name a card,
-- and the names are stamped on the SOURCE, each under its chooser, so a later
-- clause of the same resolution can read them (Ancient Vendetta, Petra Sphinx,
-- Conundrum Sphinx's "the name they chose").
-- Object.chosenNames is the same store CR 614.1c's as-enters twin writes
-- (Parun.Engine.Event's EntryRewrite.ChooseCardNames arm), and
-- Parun.Engine.Filter's HasChosenName is the one reader on the match side.
--
-- APNAP (CR 101.4) over the named players, the order the entry twin's own loop
-- takes: who is asked first is public information, so it is a fact about the
-- rules rather than about PlayerId's Ord.
--
-- CHOOSE, not target: no CR 608.2b legality to re-check, and the prompt is
-- raised unconditionally because CR 201.4's offer is every card in the Oracle
-- card reference -- there is no candidate list to be short, so the "ask only
-- where two or more make it a choice" shortcut the sibling prompts take cannot
-- apply here.
--
-- The answer is not filtered HERE, the posture the entry twin already takes:
-- the engine holds no Oracle card reference to judge it against, and
-- Game.lookUpChosenName asks for the card behind it only once it is in.
-- Parun.Interpreter.policingCardNames judges it on the far side of
-- Parun.Engine.Engine.runGameAsked, where the registry is, and covers this arm
-- and the entry twin alike by covering the one Prompt they share.
--
-- ASSIGNED and not unioned in, the entry twin's own write: CR 608.2c scopes
-- "the chosen name" to the resolution that chose it, so a permanent that
-- resolves this instruction twice must answer about the SECOND name alone.
-- Petra Sphinx activated on two turns is the producer that made the difference
-- observable -- every earlier one was an instant or a sorcery, whose next cast
-- is a new object (CR 400.7) with an empty set of its own.
--
-- What the assignment costs, and no printing spends it: a resolution whose text
-- instructs a SECOND, separate choice keeps only the later name, where CR 201.4
-- read twice would leave two, and a permanent that chose as it entered (CR
-- 614.1c) would lose that name to a later resolution of its own. No card in
-- data/cards writes two ChooseCardName instructions, and none pairs an
-- as-enters choice with a resolution-time one -- Runed Halo, the pool's
-- as-enters chooser, has no activated ability, and Conjurer's Ban names once
-- (Oracle text, Scryfall, 2026-09-06). Either card would refute this.
--
-- Written to the SOURCE and not to `resolving`: Parun.Engine.PlayerEffect
-- .contextFor and the resolution's own context both ask about a source (CR
-- 113.7), and for a spell the two ids are the same object anyway.
chooseCardName :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ChooseCardName.ChooseCardName -> Game ()
chooseCardName resolving source controller legal (ChooseCardName.MkChooseCardName ref restriction) = do
  gs <- State.get
  -- CR 101.4b: each chooser is told the names the choosers before them chose.
  -- Conundrum Sphinx drives three choosers through this arm, but no test reads
  -- the payload here; Null Chamber's entry twin in Parun.Engine.Event is the
  -- proven one.
  let ask made chooser = do
        g <- State.get
        name <- Game.choose (Prompt.ChooseCardName (Decide.deciderFor chooser g) chooser source restriction made) >>= Game.lookUpChosenName
        pure (made Seq.|> (chooser, name))
  picked <- fmap (Map.fromList . Foldable.toList) (Monad.foldM ask Seq.empty (apnapDecidersOf ref legal resolving source controller gs))
  -- CR 101.3: a reference naming NOBODY leaves nothing to do, so the write is
  -- skipped rather than assigning the empty set -- which would clear a name an
  -- earlier instruction chose, and the assignment above is the whole reason
  -- that would now be visible.
  --
  -- A source that has LEFT its zone gets the names on its last known
  -- information instead (CR 608.2h), which is where Game.choiceWithLastKnown
  -- reads them back: Conundrum Sphinx bounced with its trigger on the stack
  -- still keeps a named card (its CR 608.2h scenario under data/scenarios).
  Monad.unless (Map.null picked) $
    State.modify' (Game.recordChoice Chosen.Names (Game.readingAcquisition resolving source gs source) (const (Just picked)) source)

-- CR 608.2d: Mystic Compass's "the basic land type of your choice" and
-- Persecute's "choose a color", the resolving controller's, through
-- Event.chooseQuality. Written to the SOURCE, ChooseCardName's road above,
-- under the acquisition its reader asks for (CR 607.5), and read back by the
-- next instruction's freeze (Projection.freezeQuantities' arm for
-- Modification.SetLandSubtypeToChosen), so a later activation's choice
-- rewrites the field without reaching an effect already stored. On a spell
-- the source is the resolving object itself, so a later instruction of the
-- same resolution reads it through Parun.Engine.SourceContext -- the scenario
-- cr-608-2d-persecute-discards-the-cards-of-the-color-chosen-as-it-resolves.
chooseQuality :: ObjectId -> ObjectId -> PlayerId -> ChosenQuality.ChosenQuality -> Game ()
chooseQuality resolving source controller quality = do
  gs <- State.get
  Event.chooseQuality quality controller (Game.readingAcquisition resolving source gs source) source

-- CR 400.11c: the resolving controller reveals a card they own from outside the
-- game matching the filter and puts it into their hand -- Burning Wish.
--
-- The CONTROLLER and not the owner of the source, because CR 109.5 makes the
-- card's "you" the player the effect is applied for; the two differ for a spell
-- whose control was gained. The SOURCE goes along only for the filter's context
-- (CR 113.7), the same pair the search arm's own context is built from.
--
-- Parun.Engine.Event.bringInto is the whole of it, and this arm asks nothing about
-- which effect the filter came from.
fromOutsideTheGame :: ObjectId -> PlayerId -> FromOutsideTheGame.FromOutsideTheGame -> Game ()
fromOutsideTheGame source controller payload = Event.bringInto payload source controller

-- CR 608.2n: "Exile Burning Wish" -- the resolving SPELL goes to exile as this
-- instruction runs rather than to its owner's graveyard when the resolution
-- ends. finishSpell's move afterwards finds nothing, CR 400.7 having minted a
-- fresh incarnation in exile.
--
-- `resolving` and not `source`: the two coincide for a spell, and this arm is
-- about the object ON THE STACK. The faceOf gate is what makes an ability inert
-- here -- CR 113.7a's ability object has no card behind it, so exiling it would
-- take the ability off the stack in the middle of its own resolution.
exileThisSpell :: ObjectId -> Game ()
exileThisSpell resolving = do
  gs <- State.get
  Monad.when (Maybe.isJust (Game.faceOf resolving gs)) (Event.changeZone resolving Zone.Exile)

-- CR 122: PutCounters' mirror, deliberately NOT through a CR 614.16 gate --
-- nothing in CR 614 replaces a removal.
removeCounters :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RemoveCounters.RemoveCounters -> Game ()
removeCounters resolving source controller legal (RemoveCounters.MkRemoveCounters kind quantity slot mTally) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure () -- a player recipient has no object counters
      Just target -> case Quantity.evaluateFor viewOf context gs resolving source quantity of
        Nothing -> pure () -- unevaluable quantity: no-op (the powerOf posture)
        Just n -> do
          -- What the card's "that much" reads is the number that ACTUALLY came
          -- off, so it is measured against what was there rather than against
          -- the instruction's own number -- Event.removeCounters saturates at
          -- the count on the object, and an "all" written as a stale reading
          -- would otherwise bind more than it removed. Read BEFORE the removal,
          -- there being nothing left to count after it.
          before <- State.gets (maybe 0 (Map.findWithDefault 0 kind . Object.counters) . Game.lookupObject target)
          Monad.when (n > 0) (Event.removeCounters target kind (Integer.toNaturalSaturating n))
          -- Bound even where nothing came off, which is the answer "that much"
          -- wants: Ashling the Pilgrim with no counters deals 0 damage rather
          -- than leaving the clause unanswered.
          Monad.forM_ mTally $ \tally -> State.modify' (bindAmountSlot resolving source tally (min before (Integer.toNaturalSaturating n)))
    _ -> pure () -- illegal slot at resolution (CR 608.2b): no-op

removeCountersAmong :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RemoveCountersAmong.RemoveCountersAmong -> Game ()
removeCountersAmong resolving source controller legal (RemoveCountersAmong.MkRemoveCountersAmong count fromRef which mTally) = do
  -- CR 608.2d: the resolving controller divides the removal among the
  -- permanents the ObjectRef names that carry the kind, through the cost
  -- side's division prompts (Parun.Engine.Cost's RemoveCounters arm). An
  -- answer that does not add up is not repaired into another choice: it takes
  -- the least the card allows.
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      permanents = objectRefObjects legal resolving controller source gs fromRef
      decider = Decide.deciderFor controller gs
      asked quantity = case Quantity.evaluateFor viewOf context gs resolving source quantity of
        Just n | n > 0 -> Integer.toNaturalSaturating n
        _ -> 0
  removed <- case which of
    WhichCounters.OfKind kind -> do
      let offered = carrying gs kind permanents
      division <- case count of
        RemovalCount.Exactly quantity
          -- CR 609.3 where fewer are there than the card names, which a "may"
          -- never reaches (effectIsImpossible); elided where the division is the
          -- only one.
          | sum offered <= asked quantity || Map.size offered == 1 -> pure (Cost.fillInOrder (asked quantity) offered)
          | otherwise -> do
              answer <- Game.choose (Prompt.ChooseCounterRemovalAmong decider controller source (asked quantity) offered)
              pure (if Cost.dividesRemoval (asked quantity) offered answer then answer else Cost.fillInOrder (asked quantity) offered)
        RemovalCount.UpTo quantity
          | asked quantity == 0 || Map.null offered -> pure Map.empty
          | otherwise -> do
              answer <- Game.choose (Prompt.ChooseCounterRemovalUpTo decider controller source (asked quantity) offered)
              pure (if sum answer <= asked quantity && Cost.withinOffer offered answer then answer else Map.empty)
        RemovalCount.AnyNumber
          | Map.null offered -> pure Map.empty
          | otherwise -> do
              answer <- Game.choose (Prompt.ChooseCounterRemovalAtLeast decider controller source 0 offered)
              pure (if Cost.withinOffer offered answer then answer else Map.empty)
      Monad.forM_ (Map.toList (Map.filter (> 0) division)) (\(permanent, taken) -> Event.removeCounters permanent kind taken)
      pure (sum division)
    -- CR 122.1: with no kind named, the division is by kind as well
    -- (Eventide's Shadow), through the cost side's mixed prompt at a floor of
    -- zero. Only "any number" reaches here: Parun.Codec.RemoveCountersAmong
    -- rejects any kind at a stated count, which no printing writes.
    WhichCounters.OfAnyKind -> case count of
      RemovalCount.AnyNumber -> do
        let offered = removableAmong gs which permanents
        division <- case Cost.onlyMixedDivision CounterSpread.FromAmongAtLeast 0 offered of
          Just only -> pure only
          Nothing -> do
            answer <- Game.choose (Prompt.ChooseMixedCounterRemoval decider controller source CounterSpread.FromAmongAtLeast 0 offered)
            pure (if Cost.dividesMixedRemoval CounterSpread.FromAmongAtLeast 0 offered answer then answer else Map.empty)
        let flat = Cost.flattenMixed division
        Monad.forM_ (Map.toList flat) (\((permanent, kind), taken) -> Event.removeCounters permanent kind taken)
        pure (sum flat)
      RemovalCount.Exactly _ -> pure 0
      RemovalCount.UpTo _ -> pure 0
  -- Bound even where nothing came off, Effect.RemoveCounters' posture.
  Monad.forM_ mTally $ \tally -> State.modify' (bindAmountSlot resolving source tally removed)

moveCounters :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> MoveCounters.MoveCounters -> Game ()
moveCounters resolving source controller legal (MoveCounters.MkMoveCounters fromRef kinds mSlot toRef) = do
  -- CR 122.5: move counters off one permanent and onto a second. WHICH kinds
  -- cross is the card's call when it names one (Explorer's Cache's "move a
  -- +1/+1 counter" and Spike Cannibal's "move all +1/+1 counters"), the
  -- player's when it names none (Agent's Toolkit's "move a counter",
  -- Resourceful Defense's "move any number of counters" and Takesies' "up to
  -- one counter", which alone lets the player decline, and Goldberry,
  -- River-Daughter's "one or more counters", which alone puts a floor under
  -- the answer), shared when the card
  -- names the kind and the player supplies the count (Scrounging Bandar's
  -- "move any number of +1/+1 counters"), and neither's when the card takes
  -- them all (Fate Transfer's "move all counters") or reads the
  -- DESTINATION for them (Goldberry, River-Daughter's "a counter of each kind
  -- not on Goldberry"), which is what `kinds` holds. HOW MANY first objects
  -- there are is `from`, an ObjectRef: one for every producer that names a
  -- permanent, a whole battlefield sweep for Spike Cannibal's "all creatures".
  -- HOW MANY SECOND objects there are is `to`, an ObjectRef the same way:
  -- Forgotten Ancient's "onto other creatures" is a whole group, and the
  -- player then says how many counters land on each (distributePair below).
  -- ATOMIC -- "if either of these actions isn't possible, it's not possible to
  -- move a counter, and no counter is removed from or put onto anything" -- so
  -- every impossibility the rule names is checked BEFORE either half runs, and
  -- this arm is not a RemoveCounters followed by a PutCounters however much its
  -- tail looks like one.
  --
  -- All four of the rule's impossibilities are checked here, in its own order.
  -- Its third, "the second object can't have counters put onto it", is a
  -- PROHIBITION (Solemnity, Melira Sylvok Outcast) and not a replacement, so it
  -- is Parun.Engine.CounterRestriction rather than a CR 614.16 row -- a row that
  -- scales the placement to nothing is NOT that case: the placement was
  -- possible and was replaced, which rule 122.5 does not undo.
  --
  -- That third impossibility is asked PER KIND, which is what makes it part of
  -- the candidate sweep below rather than a gate beside the two zone reads:
  -- Melira names one kind, so a destination that can't take a -1/-1 counter may
  -- still take a +1/+1 one. A kind the destination refuses is not a kind this
  -- move could choose, and rule 122.5's atomicity is why it is dropped from the
  -- candidates rather than chosen and then half-performed -- "no counter is
  -- removed from or put onto anything". Under "all counters" that is per kind
  -- too, and under "a counter of each kind not on Goldberry" likewise: the
  -- refused kind stays where it is and every other kind still crosses, since
  -- each kind is its own pair of actions and the rule's all-or-nothing is
  -- stated about one counter, not about the sentence that moved it.
  --
  -- The two halves go through Event.removeCounters and Event.putCounters, so the
  -- move records both crossings -- a CR 122.7 "when the Nth counter is put on"
  -- trigger sees the arrival, and rule 122.5's own reading is that a move IS
  -- those two actions. Never one pair per counter, CR 614.16's own unit being
  -- "one or more counters" and the call Parun.Types.PutCounters already made.
  -- The two halves batch DIFFERENTLY, which the sweep below is what forces: one
  -- removal per kind PER FIRST OBJECT, since a removal is off one object and
  -- rule 122.5 pairs it with one; one placement per kind PER DESTINATION, since
  -- CR 608.2f processes an action taken on several objects simultaneously and
  -- every pair's counters land on the destination its own answer named. Where
  -- `to` names ONE object -- every printing but Forgotten Ancient -- that is one
  -- placement per kind for the whole instruction however many first objects the
  -- sweep gathered from; where it names a group the placements are one per
  -- recipient per kind and batch no further, an arrival being on one object.
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- CR 122.5's SECOND side, swept exactly as the first is and by the same
      -- reader: an ObjectRef, so a slot naming one target is one destination
      -- (CR 608.2b's re-read inside objectRefObjects), a slot bound to a group
      -- is every member of it, and Forgotten Ancient's "other creatures" is
      -- ObjectRef.EachMatching's battlefield fold.
      recipients = objectRefObjects legal resolving controller source gs toRef
      -- HOW MANY of the appropriate kind the card asks for -- Black Panther,
      -- Wakandan King's "all +1/+1 counters", written as the count of that kind
      -- on the object the `from` slot names. Zero for CR 107.2's undeterminable
      -- count and CR 107.1b's negative one alike, freezeRiders' posture.
      askedFor quantity = case Quantity.evaluateFor viewOf context gs resolving source quantity of
        Just n | n > 0 -> Integer.toNaturalSaturating n
        _ -> 0
      -- CR 122.5's pair, performed once per object the FIRST side names:
      -- Spike Cannibal's "from all creatures" sweeps a group, and every
      -- member is its own pair against the one destination, with the rule's
      -- four impossibilities asked afresh for each.
      movePair to from = case from of
        _
          -- "This may occur if the first and second objects are the same object".
          | movablePair gs from to ->
              -- "... or if either object is no longer in the correct zone". CR 122.1
              -- puts a counter on "an object or player", and CR 122.1a/122.1b
              -- contemplate counters on a card in a zone other than the battlefield,
              -- so the battlefield is not the correct zone by the rule alone -- it is
              -- the correct zone for THIS opcode because every producer in
              -- data/cards/ names permanents on both sides, in every combination the
              -- pool writes (Agent's Toolkit binds the artifact itself and the
              -- creature that entered; Explorer's Cache binds the artifact and a
              -- targeted creature; Black Panther, Wakandan King binds a targeted land
              -- and a targeted creature; Fate Transfer binds two targeted creatures;
              -- Goldberry, River-Daughter binds a targeted permanent and herself,
              -- and her second ability the two the other way about; Scrounging
              -- Bandar binds itself and a targeted creature, where Bioshift binds
              -- two targeted ones; Spike Cannibal sweeps every creature on the
              -- battlefield onto itself; Takesies sweeps every permanent onto a
              -- targeted one; Forgotten Ancient sweeps itself onto every other
              -- creature). A slot bound as the ability triggered may
              -- name an object CR 400.7 has since moved, and a targeted one may have
              -- become illegal, which is CR 608.2b's re-read in the legalMany inside
              -- objectRefObjects.
              --
              -- The `from` half answers CR 702.26b as much as CR 400.7, and both are
              -- proven boards. Parun.Engine.Phasing spells "treated as though it does
              -- not exist" by moving the object OUT of GameState.battlefield, while
              -- CR 702.26d leaves its counters and its Object.zone alone -- so a
              -- phased-out source is off the battlefield still bearing every kind,
              -- and without this read the candidate sweep below would strip one off
              -- it. Parun.MoveCounterSpec's Reality Ripple case is that board; its
              -- sacrifice case is CR 122.2's.
              --
              -- "... if the first object doesn't have the appropriate kind of
              -- counter on it". Which kinds are appropriate is the one place the
              -- printed spellings part, and rule 122.5's clause reads differently
              -- under each.
              --
              -- `onFrom` drops the kinds rule 122.5's THIRD impossibility rules out
              -- as well as the ones the first object does not have, so every
              -- spelling answers it in one place: a kind the destination refuses is
              -- not appropriate for this move, whether the card named it, the
              -- player would have, the card took every kind, or the destination's
              -- own tally settled it. Rule 122.5's atomicity is why it is dropped
              -- here rather than half-performed -- "no counter is removed from or
              -- put onto anything".
              let onFrom = movableCounters gs from to
                  -- CR 609.3 for a count larger than the object has: "it does only
                  -- as much as possible". The clamp is load-bearing --
                  -- Event.removeCounters saturates where Event.putCounters does not,
                  -- so an unclamped pair would place more counters than it took off
                  -- -- and PROVEN by the AnyNumber arm below: no card in the corpus
                  -- writes a count the object it reads cannot cover, but a PLAYER's
                  -- answer is under no such constraint, so Parun.MoveCounterSpec's
                  -- "an answer asking for more counters than the permanent has"
                  -- case is where the two differ. It also subsumes rule 122.5's
                  -- second impossibility, a kind the first object does not have at
                  -- all: `onFrom` answers zero and nothing crosses.
                  --
                  -- The REMOVAL half alone, reporting per kind what it took off
                  -- THIS first object. The placement half is deliberately not here:
                  -- it happens once for the whole instruction, below the sweep, which
                  -- is CR 608.2f's FIRST branch -- "in most cases, each such action is
                  -- processed simultaneously". Nothing about removals off distinct
                  -- objects beside one batch of placements onto a single object
                  -- cannot be processed simultaneously, so the rule's individual
                  -- fallback and its APNAP ordering never engage. A group source is
                  -- exactly where the two branches part: one placement of nine is
                  -- one CR 614.16 opportunity and one CR 122.7 arrival, where three
                  -- placements of four, three and two are three of each.
                  move kind asked =
                    let taken = min asked (Map.findWithDefault 0 kind onFrom)
                     in if taken == 0
                          then pure Map.empty
                          else do
                            Event.removeCounters from kind taken
                            pure (Map.singleton kind taken)
               in case kinds of
                    -- "Move all counters": every kind the first object has, the whole
                    -- tally of each, with nothing asked and nothing to name. Ascending
                    -- (Map.toList), so a transcript is deterministic, and SUMMED,
                    -- since "moved this way" counts counters and not kinds.
                    MovedKinds.Every -> fmap (Map.unionsWith (+)) (mapM (uncurry move) (Map.toList onFrom))
                    -- The card named the kind, so the appropriate kind is that one
                    -- and NOTHING is asked: a prompt offering the single option the
                    -- card already settled would be the engine putting a decision
                    -- where the rules leave none.
                    MovedKinds.Named wanted quantity -> move wanted (askedFor quantity)
                    -- Spike Cannibal's "move all +1/+1 counters": the card named
                    -- the kind and asks nothing, Named's reason, and the count is
                    -- the whole tally THIS first object bears rather than a number
                    -- the sentence evaluates once. `onFrom` already dropped a kind
                    -- the destination refuses, so a wanted kind missing from it
                    -- answers zero and nothing crosses.
                    MovedKinds.EveryOfKind wanted -> move wanted (Map.findWithDefault 0 wanted onFrom)
                    -- No kind named: the kinds actually on it ARE the candidates, so
                    -- an object bearing none -- or bearing only kinds the
                    -- destination refuses -- leaves nothing to move and nothing to
                    -- ask. Ascending (Map.keys), so a transcript is deterministic.
                    --
                    -- The whole count comes out of the ONE kind picked; the sweep
                    -- behind that is Parun.Types.MovedKinds' haddock.
                    MovedKinds.Chosen quantity ->
                      -- A count of zero moves nothing and ASKS nothing: the prompt
                      -- below picks which kind crosses, and no kind crossing makes
                      -- that a question whose answer cannot matter. A REGRESSION
                      -- FENCE, not a proven behaviour -- the one producer reaching
                      -- THIS arm has a literal count of one, so a mutation dropping
                      -- this guard leaves the suite green.
                      let asked = askedFor quantity
                       in if asked == 0
                            then pure Map.empty
                            else do
                              -- Through Game.chooseAmong: one kind on the object
                              -- leaves nothing to decide.
                              picked <- Game.chooseAmong (\decider who -> Prompt.ChooseCounterKind decider who (CounterKindFor.MovedBetween from to)) controller (Map.keys onFrom)
                              maybe (pure Map.empty) (`move` asked) picked
                    -- Resourceful Defense's "move any number of counters": the card
                    -- settles neither the kind nor the count, so ONE prompt asks for
                    -- both and the answer may spread across kinds -- which is the
                    -- whole of what separates this arm from Chosen above. Ascending
                    -- (Map.toList), so a transcript is deterministic.
                    --
                    -- An object with no movable kind moves nothing and asks nothing.
                    -- Everywhere else the prompt IS raised, a single kind bearing a
                    -- single counter included, because "any number" includes none:
                    -- moving it and leaving it are two different boards, so eliding
                    -- the question would be the engine making the player's choice.
                    MovedKinds.AnyNumber ->
                      if Map.null onFrom
                        then pure Map.empty
                        else do
                          answer <- Game.choose (Prompt.ChooseMovedCounters (Decide.deciderFor controller gs) controller from to onFrom)
                          -- FILTERED, NOT TRUSTED, in `move` rather than here: it
                          -- already reads `onFrom` for the count, so a kind the object
                          -- does not have -- or one the destination refuses, which
                          -- `onFrom` dropped -- answers zero and moves nothing, and a
                          -- count above what the object holds is clamped to it. A
                          -- filter written here as well would have no observer.
                          fmap (Map.unionsWith (+)) (mapM (uncurry move) (Map.toList answer))
                    -- Goldberry, River-Daughter's "move one or more counters":
                    -- AnyNumber's question above with the empty answer struck
                    -- out, which is the whole of what separates the two arms.
                    -- The card states a floor, so a player holding a movable
                    -- counter must move one; the prompt is its own
                    -- (Prompt.ChooseMovedCountersAtLeastOne) because an
                    -- answerer that cannot see the floor cannot answer within
                    -- it.
                    --
                    -- An object with no movable kind moves nothing and asks
                    -- nothing: the floor is what the card can ask for, not
                    -- what rule 122.5 can perform, and its second
                    -- impossibility still empties the batch.
                    MovedKinds.AtLeastOne ->
                      if Map.null onFrom
                        then pure Map.empty
                        else do
                          answer <- Game.choose (Prompt.ChooseMovedCountersAtLeastOne (Decide.deciderFor controller gs) controller from to onFrom)
                          -- FILTERED, NOT TRUSTED, in two steps where AnyNumber
                          -- needs one. A kind the object does not have is dropped
                          -- and a count above what it holds is clamped, which
                          -- Map.intersectionWith does here rather than leaving it
                          -- to `move` -- the floor has to be read off the answer
                          -- AS FILTERED, since an answer naming only kinds that
                          -- are not there moves nothing. An answer that then still
                          -- moves nothing is repaired to one counter of the first
                          -- kind offered (Map.lookupMin, so a transcript is
                          -- deterministic): the card says one or more must cross,
                          -- and rule 122.5 performs the move wherever it is
                          -- possible.
                          let clamped = Map.filter (> 0) (Map.intersectionWith min answer onFrom)
                              floored =
                                if Map.null clamped
                                  then foldMap (\(kind, _) -> Map.singleton kind 1) (Map.lookupMin onFrom)
                                  else clamped
                          fmap (Map.unionsWith (+)) (mapM (uncurry move) (Map.toList floored))
                    -- Scrounging Bandar's "move any number of +1/+1
                    -- counters": the card names the kind and leaves the count
                    -- to the player, so the prompt above is raised over the ONE
                    -- kind the card named rather than over every kind the object
                    -- bears. That is what keeps this arm from being AnyNumber:
                    -- offering the rest would let the answerer move a counter
                    -- the card never mentioned.
                    --
                    -- The same prompt and not a bespoke one: its Map is what the
                    -- move could really carry, and a card naming its kind narrows
                    -- that to a single key exactly as `onFrom` narrows it to the
                    -- kinds present. The answer is FILTERED the same way too, by
                    -- reading only the named kind out of it.
                    --
                    -- A first object bearing none of that kind moves nothing and
                    -- asks nothing -- rule 122.5's second impossibility with no
                    -- question left behind it. Everywhere else the prompt IS
                    -- raised, a lone counter included, AnyNumber's reason above.
                    MovedKinds.AnyNumberOfKind wanted ->
                      case Map.lookup wanted onFrom of
                        Nothing -> pure Map.empty
                        Just available -> do
                          answer <- Game.choose (Prompt.ChooseMovedCounters (Decide.deciderFor controller gs) controller from to (Map.singleton wanted available))
                          move wanted (Map.findWithDefault 0 wanted answer)
                    -- Goldberry, River-Daughter's "a counter of each kind not on
                    -- Goldberry": one counter of every kind the FIRST object has
                    -- that the SECOND does not, which names no kind, prints no
                    -- count and asks nothing -- the destination's own tally is the
                    -- whole of the decision, so a prompt here would be the engine
                    -- putting a choice where the card leaves none. Ascending
                    -- (Map.keys), so a transcript is deterministic.
                    --
                    -- `onTo` is read from the SAME pre-move snapshot as `onFrom`,
                    -- which is not a stale read but the rule's own reading: "each
                    -- kind not on Goldberry" is settled once for the whole sentence,
                    -- and the kinds it selects are by construction absent from the
                    -- destination, so no kind this arm moves can make a later kind
                    -- ineligible however the batch is ordered.
                    --
                    -- Kinds the destination holds at zero count as absent: CR 122.1
                    -- makes a counter a marker that is on the object or is not, and
                    -- Object.counters keeps a key whose counters have all been
                    -- removed.
                    MovedKinds.EachAbsentKind ->
                      let onTo = Map.filter (> 0) (maybe Map.empty Object.counters (Game.lookupObject to gs))
                          absent = Map.keys (Map.withoutKeys onFrom (Map.keysSet onTo))
                       in fmap (Map.unionsWith (+)) (mapM (`move` 1) absent)
                    -- Takesies' "move up to one counter from each permanent":
                    -- Chosen's question -- which kind, out of the kinds this
                    -- first object actually has -- with declining added, and
                    -- one counter of whichever kind is picked. Ascending
                    -- (Map.keys), so a transcript is deterministic.
                    --
                    -- The prompt is raised for a SINGLE candidate as well,
                    -- AnyNumber's reason rather than Chosen's: "up to one"
                    -- includes none, so moving the one kind and leaving it are
                    -- two different boards and the question is real.
                    MovedKinds.UpToOneChosen ->
                      -- FILTERED, NOT TRUSTED: an answer naming a kind that is
                      -- not on the object is read as declining, which is
                      -- Chosen's filter under a wording where declining is
                      -- itself legal -- there the answer had to fall back to a
                      -- kind, since rule 122.5 moves a counter wherever it can.
                      Game.mayChooseAmong (\decider who -> Prompt.ChooseMovedCounterOrNone decider who from to) controller (Map.keys onFrom)
                        >>= maybe (pure Map.empty) (`move` 1)
        -- Rule 122.5's impossibilities above: THIS pair moves nothing and the
        -- others in the sweep are untouched, the rule's all-or-nothing being
        -- stated about one pair. A destination that resolves to no object at
        -- all -- an illegal slot at resolution (CR 608.2b), a player recipient
        -- -- never reaches here, `recipients` being empty instead.
        _ -> pure Map.empty
      -- movePair's sibling for a destination naming a GROUP: Forgotten
      -- Ancient's "move any number of +1/+1 counters from this creature onto
      -- other creatures". One first object against many second objects, where
      -- movePair is one against one, and the pairs it makes are rule 122.5's
      -- own -- so its four impossibilities are asked afresh for each recipient
      -- rather than once for the sentence.
      --
      -- WHERE each counter goes is the player's, which is what makes this a
      -- prompt rather than a fold (Prompt's ChooseDistributedMovedCounters),
      -- and the prompt's MoveSpread states the total the answer must reach.
      -- Where the card leaves the count open ("any number") that is anything
      -- up to the offered tallies; under a floor ("one or more") at least one
      -- counter; and where the card settles the batch ("all +1/+1 counters",
      -- "two +1/+1 counters") every counter of it, since rule 122.5's
      -- all-or-nothing forbids removing a counter that has nowhere to land.
      -- Where the player picks the kind ("two counters of one kind") it is
      -- that many of one kind, and under "up to one counter" at most one.
      --
      -- Not implemented: a group destination under MovedKinds.EachAbsentKind,
      -- which reads the one destination and moves nothing here (#4774).
      distributePair candidates fromOne =
        -- Rule 122.5's first and fourth impossibilities, per recipient: the
        -- first object is not its own destination, and both ends are on the
        -- battlefield. A recipient failing either is not a pair this move can
        -- make and is simply not offered.
        let others = NonEmpty.filter (\to -> to /= fromOne && Set.member to (GameState.battlefield gs)) candidates
            -- Rule 122.5's third impossibility, asked of one pair at a time.
            takes kind to = not (CounterRestriction.prohibited to kind gs)
         in if not (Set.member fromOne (GameState.battlefield gs))
              then pure Map.empty
              else case others of
                [] -> pure Map.empty
                firstTo : moreTo ->
                  -- movePair's `onFrom` read across the whole group: a kind is
                  -- appropriate here if SOME recipient can take it. Which
                  -- recipient may take which kind is then asked again as the
                  -- answer is filtered below.
                  let onFrom =
                        Map.filterWithKey
                          (\kind n -> n > 0 && any (takes kind) others)
                          (maybe Map.empty Object.counters (Game.lookupObject fromOne gs))
                      ofKind wanted = Map.restrictKeys onFrom (Set.singleton wanted)
                      question = case kinds of
                        MovedKinds.AnyNumber -> Just (MoveSpread.AnyNumber, onFrom)
                        MovedKinds.AnyNumberOfKind wanted -> Just (MoveSpread.AnyNumber, ofKind wanted)
                        MovedKinds.AtLeastOne -> Just (MoveSpread.AtLeastOne, onFrom)
                        -- The batch the card settles, movePair's arms of the
                        -- same names read across the group: every kind's whole
                        -- tally, one kind's whole tally, and the named kind
                        -- clamped to what is there (CR 609.3).
                        MovedKinds.Every -> Just (MoveSpread.Exactly, onFrom)
                        MovedKinds.EveryOfKind wanted -> Just (MoveSpread.Exactly, ofKind wanted)
                        MovedKinds.Named wanted quantity -> Just (MoveSpread.Exactly, Map.filter (> 0) (fmap (min (askedFor quantity)) (ofKind wanted)))
                        -- Agent's Toolkit's "move a counter" read across the
                        -- group: one kind the player picks and that many of
                        -- it. A lone kind on the first object leaves only the
                        -- recipients to ask, so the batch is settled; a count
                        -- of zero asks nothing, movePair's Chosen arm.
                        MovedKinds.Chosen quantity -> case Map.toList onFrom of
                          [(kind, held)] -> Just (MoveSpread.Exactly, Map.filter (> 0) (Map.singleton kind (min (askedFor quantity) held)))
                          _
                            | askedFor quantity == 0 -> Nothing
                            | otherwise -> Just (MoveSpread.OneKind (askedFor quantity), onFrom)
                        -- Takesies' "up to one counter": one counter of any
                        -- kind onto any recipient, or none.
                        MovedKinds.UpToOneChosen -> Just (MoveSpread.UpToOne, onFrom)
                        MovedKinds.EachAbsentKind -> Nothing
                      -- Places `owed` counters of each kind on the first
                      -- recipient, in offered order, that takes that kind --
                      -- one exists for every kind `onFrom` kept.
                      topUp owed acc =
                        Map.foldrWithKey
                          ( \kind n placed -> case filter (takes kind) others of
                              to : _ | n > 0 -> Map.insertWith (Map.unionWith (+)) to (Map.singleton kind n) placed
                              _ -> placed
                          )
                          acc
                          owed
                      -- Every offered kind that one recipient alone can take:
                      -- a settled batch then has one legal distribution.
                      --
                      -- The `takes` reads here and in `topUp` are a
                      -- regression fence: every group in the pool leaves
                      -- `others` two or more recipients, and the pool's
                      -- prohibitions (Solemnity; Melira, Sylvok Outcast)
                      -- refuse a kind on every creature one player controls
                      -- alike, so no board refuses it on one recipient of
                      -- "other creatures you control" alone.
                      forced offered = all (\kind -> length (filter (takes kind) others) == 1) (Map.keys offered)
                      -- The first `n` counters of an allocation, recipients in
                      -- offered order and kinds ascending, so a transcript is
                      -- deterministic.
                      capAt n allocation =
                        let keep (left, acc) to =
                              let (left', kept) = Map.mapAccum (\held wanted -> let taken = min held wanted in (held - taken, taken)) left (Map.findWithDefault Map.empty to allocation)
                                  kept' = Map.filter (> 0) kept
                               in (left', if Map.null kept' then acc else Map.insert to kept' acc)
                         in snd (List.foldl' keep (n, Map.empty) others)
                   in case question of
                        Nothing -> pure Map.empty
                        Just (spread, offered)
                          | Map.null offered -> pure Map.empty
                          | otherwise -> do
                              -- Nothing is asked of a settled batch whose
                              -- every counter has one place to land.
                              allocated <-
                                if spread == MoveSpread.Exactly && forced offered
                                  then pure (topUp offered Map.empty)
                                  else do
                                    answer <- Game.choose (Prompt.ChooseDistributedMovedCounters (Decide.deciderFor controller gs) controller fromOne spread offered (firstTo NonEmpty.:| moreTo))
                                    -- FILTERED, NOT TRUSTED: an object that was
                                    -- not offered is dropped (the fold is over
                                    -- `others`), a kind that was not offered is
                                    -- dropped, a kind the recipient itself
                                    -- refuses is dropped, and the tallies are
                                    -- clamped in offered order to what the
                                    -- first object actually holds (CR 609.3's
                                    -- "only as much as possible"). Clamping in
                                    -- an order rather than proportionally is
                                    -- what keeps a transcript deterministic; an
                                    -- honest answer never reaches it.
                                    let step (remaining, acc) to =
                                          let wanted = Map.restrictKeys (Map.findWithDefault Map.empty to answer) (Map.keysSet offered)
                                              granted = Map.filter (> 0) (Map.mapMaybeWithKey (\kind n -> if takes kind to then Just (min n (Map.findWithDefault 0 kind remaining)) else Nothing) wanted)
                                           in (Map.differenceWith (\held n -> Just (held - n)) remaining granted, if Map.null granted then acc else Map.insert to granted acc)
                                        (unplaced, filtered) = List.foldl' step (offered, Map.empty) others
                                    -- An answer outside the spread is then
                                    -- REPAIRED, Chosen's fallback posture: a
                                    -- floor answered with nothing takes one
                                    -- counter of the first kind offered
                                    -- (Map.lookupMin); a settled batch places
                                    -- what the answer left over, each onto the
                                    -- first recipient taking it; one kind keeps
                                    -- the lowest kind answered (else the first
                                    -- offered), capped and topped up to its
                                    -- count; and "up to one" keeps the first
                                    -- counter answered.
                                    pure $ case spread of
                                      MoveSpread.AnyNumber -> filtered
                                      MoveSpread.AtLeastOne
                                        | Map.null filtered -> topUp (foldMap (\(kind, _) -> Map.singleton kind 1) (Map.lookupMin offered)) Map.empty
                                        | otherwise -> filtered
                                      MoveSpread.Exactly -> topUp (Map.filter (> 0) unplaced) filtered
                                      MoveSpread.OneKind n ->
                                        case Map.lookupMin (Map.unionsWith (+) (Map.elems filtered)) <|> Map.lookupMin offered of
                                          Nothing -> Map.empty
                                          Just (kind, _) ->
                                            let owed = min n (Map.findWithDefault 0 kind offered)
                                                kept = capAt owed (Map.filter (not . Map.null) (fmap (`Map.restrictKeys` Set.singleton kind) filtered))
                                             in topUp (Map.singleton kind (owed - sum (fmap sum kept))) kept
                                      MoveSpread.UpToOne -> capAt 1 filtered
                              -- The REMOVAL half, once per kind for this first
                              -- object however many recipients share it:
                              -- movePair's batching, CR 608.2f's first branch.
                              -- The placements are below the sweep with the
                              -- single-destination ones, and cannot batch across
                              -- recipients, an arrival being on one object.
                              Monad.forM_ (Map.toList (Map.unionsWith (+) (Map.elems allocated))) $ \(kind, n) ->
                                Monad.when (n > 0) (Event.removeCounters fromOne kind n)
                              pure allocated
  -- The FIRST side is swept as this instruction is reached (CR 608.2c), and the
  -- removals run in the order the sweep hands back -- battlefieldMatching's
  -- APNAP sort for the EachMatching arm, one object for every other arm the
  -- corpus writes. That sort is not this arm's reason for ordering them:
  -- rule 608.2f orders an action that CANNOT be processed simultaneously, and
  -- the placement paragraph below is why this one can. What it buys here is a
  -- deterministic transcript.
  --
  -- objectRefObjects takes EVERY recipient a slot holds, through slotGroup and
  -- then legalMany, where a bare SlotName read goes through legalOne and takes a
  -- slot naming several objects as naming none. So a slot bound to more than one
  -- object is one pair per binding here rather than an instruction that silently
  -- moves nothing -- which is the reading the printed sentences want, "from all
  -- creatures" being a group before it is a slot. That now holds on BOTH sides,
  -- neither of which is a singular read, so neither is Parun.CardSpec's
  -- singular-reader lint's business. No card in data/cards/ binds either slot
  -- plurally; the groups both sides do carry are ObjectRef.EachMatching sweeps.
  --
  -- Every read inside movePair takes the same pre-sweep snapshot, which is
  -- Effect.PutCounters' posture: one evaluation for the whole instruction. That
  -- is not a stale read, because no sibling pair can move what any of these
  -- reads asks about. The counters on the FIRST object and a prohibition on the
  -- destination are per-pair values to begin with, and so is the destination's
  -- own tally, which only MovedKinds.EachAbsentKind reads: a pair takes counters
  -- off nothing but its own first object, `from /= to` keeps the destination out
  -- of that set, and nothing is placed until the sweep has ended. Each read
  -- therefore answers what a live read would, which is the answer CR 608.2h
  -- wants either way -- it "is determined only once, when the effect is
  -- applied".
  let froms = objectRefObjects legal resolving controller source gs fromRef
  -- CR 608.2f's FIRST branch, and the whole reason the placement is not inside
  -- movePair: "in most cases, each such action is processed simultaneously", so
  -- one written instruction puts ONE batch of each kind onto the destination
  -- however many first objects it took them off. The rule's individual fallback
  -- is for an action that CANNOT be simultaneous -- Soulfire Eruption's example,
  -- where a library can only be exiled off one card at a time -- and nothing
  -- makes a single object's arrivals serial that way.
  --
  -- It is observable, which is why it is not a matter of taste: CR 614.16
  -- replaces "one or more counters" per placement, so Hardened Scales grows one
  -- batch of nine by one and three batches of four, three and two by three; and
  -- CR 122.7's "when the Nth counter is put on" sees one arrival rather than
  -- three. Parun.MoveCounterSpec's Hardened Scales case is that board.
  --
  -- ANSWERS how many counters made the whole journey, which is neither half on
  -- its own: Event.putCounters reports what landed after CR 614.16, and a row
  -- that GREW the placement added counters that never came off a first object,
  -- so they were not moved. The minimum is the journey's overlap.
  --
  -- ONE destination or a GROUP of them is the branch here, and it is the whole
  -- of what the second side's ObjectRef buys: one destination gathers every
  -- first object's counters into one batch per kind, where a group has the
  -- player say how many of each kind land on each recipient, so the placements
  -- are one per recipient per kind and can batch no further -- an arrival is on
  -- one object. Ascending by recipient and then by kind (Map.toList), so a
  -- transcript is deterministic either way, and SUMMED, since "moved this way"
  -- counts counters and not kinds.
  let place to (kind, n) = fmap (min n) (Event.putCounters (CounterCause.ByEffect controller) to kind n)
  moved <- case recipients of
    [to] -> do
      taken <- fmap (Map.unionsWith (+)) (mapM (movePair to) froms)
      fmap sum (mapM (place to) (Map.toList taken))
    firstTo : secondTo : moreTo -> do
      allocated <- fmap (Map.unionsWith (Map.unionWith (+))) (mapM (distributePair (firstTo NonEmpty.:| (secondTo : moreTo))) froms)
      fmap sum (mapM (\(to, batch) -> fmap sum (mapM (place to) (Map.toList batch))) (Map.toList allocated))
    -- A destination naming no object at all: an illegal slot at resolution (CR
    -- 608.2b), a player recipient, or a filter nothing on the battlefield
    -- matches. Nothing crosses and nothing is asked, and the slot below is
    -- still bound -- to zero.
    [] -> pure 0
  -- "Counters moved this way", for a later effect of the same resolution to read
  -- as Quantity.InSlot -- Destroy's `slot` above in every respect, bound onto
  -- this effect's SOURCE and bound even when nothing moved, since zero is an
  -- answer where an unbound slot would leave the rider's gate unevaluable.
  Monad.forM_ mSlot $ \slot -> State.modify' (bindAmountSlot resolving source slot moved)

-- CR 701.34a: choose any number of permanents and/or players that have a
-- counter, then give each one more of every kind it already has. "That have
-- a counter" is the candidate filter, and "any number" is why a lone
-- candidate is still asked about.
--
-- Candidates and kinds are read BEFORE the prompt and before any counter
-- lands (CR 608.2h), so a CR 614 replacement cannot widen the kinds.
-- Targetless: no CR 608.2b legality to re-check.
--
-- The roster is Game.stillPlaying, not the keys of GameState.players, whose
-- departed seats keep counters CR 800.4a does not remove.
--
-- CR 614.1a: the instruction is first proposed as WouldPerform, so a row
-- like Tekuthal, Inquiry Dominus's can make it several proliferates -- each its
-- own CR 701.34a choice, read off the board the previous one left. No
-- printed row cancels the event; a cancelled one proliferates nothing.
proliferate :: ObjectId -> PlayerId -> Game ()
proliferate source controller = do
  outcome <- Event.applyReplacements (ProposedEvent.WouldPerform PlayerInstruction.Proliferate Nothing controller 1)
  Monad.forM_ (outcome >>= Replacement.asPerformed PlayerInstruction.Proliferate) $ \(_, times) ->
    Monad.replicateM_ (Natural.toIntSaturating times) (proliferateOnce source controller)

-- CR 701.39a: "bolster N" -- put N +1/+1 counters on a creature you control
-- with the least toughness, or tied for least. The prompt is raised only for a
-- TIE; CR 101.3 ignores the instruction when the pool is empty. Targetless: no
-- CR 608.2b legality to re-check.
--
-- Toughness is the PROJECTED value (CR 613.1g's layer 7); a creature the
-- projection gives no toughness is dropped rather than sorted as zero, and the
-- pool is swept before the counters land (CR 608.2h).
bolster :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Quantity.Type.Quantity -> Game ()
bolster resolving source controller legal quantity = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- Ascending, so the single-candidate shortcut and a transcript are
      -- deterministic.
      creatures = List.sort (filter (\oid -> Projection.isCreatureOf oid gs) (Projection.controls controller gs))
      measured = Maybe.mapMaybe (\oid -> fmap ((,) oid) (Projection.toughnessOf oid gs)) creatures
  case Quantity.evaluateFor viewOf context gs resolving source quantity of
    Nothing -> pure () -- unevaluable quantity: no-op (the powerOf posture)
    Just n -> case measured of
      -- CR 101.3: a player controlling no creature bolsters nothing.
      [] -> pure ()
      first : rest -> do
        let least = minimum (fmap snd (first : rest))
            tied = fmap fst (filter ((== least) . snd) (first : rest))
        -- Through Game.chooseAmong. Nothing is unreachable by construction,
        -- `least` being the minimum OF this list; the fallback keeps the
        -- mandatory action mandatory.
        bolstered <- Maybe.fromMaybe (fst first) <$> Game.chooseAmong (\decider who -> Prompt.ChooseBolster decider who resolving) controller tied
        -- CR 122.6: through the single funnel, so CR 614.16's counter
        -- replacements get their opportunity.
        Monad.when (n > 0) . Monad.void $
          Event.putCounters (CounterCause.ByEffect controller) bolstered CounterKind.PlusOnePlusOne (Integer.toNaturalSaturating n)

-- CR 701.66a: "earthbend N" -- the whole keyword action, whose three
-- instructions Parun.Engine.Earthbend writes as Effects and this arm runs
-- through the SAME executor a card's own instructions run through. Nothing
-- here reads which effects those are.
--
-- TARGETS, alone among the rule 701 arms: rule 701.66a says "target land you
-- control", so the card declares the slot and CR 608.2b has already narrowed
-- `legal` by the time this runs. An illegal or unfilled slot leaves `lands`
-- empty and the ObjectRef sweeps inside the instructions empty too, so the
-- whole action is a no-op rather than a partial one.
--
-- THE SWEEP IS REPEATED, once per instruction, where CR 608.2f would enumerate
-- once. Indistinguishable here and only here: rule 701.66a names ONE target,
-- and no instruction in the list moves it, changes who controls it or changes
-- whether it is a land, so every sweep answers the same id.
--
-- The land is bound under Binding.earthbentLand BEFORE the arming opcode and
-- after the counters, which is CR 608.2c's written order plus CR 603.7c: the
-- delayed ability captures the resolving object's whole environment, and this
-- is the slot its condition names.
earthbendArm :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Earthbend.Type.Earthbend -> Game ()
earthbendArm runSubgame resolving source controller legal chosen earthbend = do
  gs <- State.get
  let lands = objectRefObjects legal resolving controller source gs (Earthbend.Type.ref earthbend)
  Monad.forM_ (Earthbend.instructions earthbend) (applyEffectWith runSubgame resolving source controller legal chosen)
  Monad.forM_ lands $ \land -> do
    State.modify' (bindEarthbentLand resolving land)
    applyEffectWith runSubgame resolving source controller legal chosen Earthbend.arm
    -- CR 701.66b: the earthbend as a game event, written where the rule puts
    -- it -- AFTER the arming opcode above, so the moment recorded is the
    -- creation of rule 701.66a's delayed triggered ability and not that
    -- ability's own later resolution. Parun.EventTriggerSpec's "CR 701.66b the
    -- Adept fires as rule 701.66a's delayed ability is created, not when it
    -- returns the land" proves the two apart.
    --
    -- Inside the per-land loop: rule 701.66a arms one delayed ability per
    -- target, so a hypothetical instruction naming two lands earthbends twice,
    -- and one whose target CR 608.2b dropped earthbends not at all.
    --
    -- `controller` is CR 109.5's "you", which rule 701.66a's "target land YOU
    -- control" and CR 603.7d's controller of the delayed ability agree on.
    State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Earthbend controller)))

-- CR 701.65a: "airbend" -- the whole keyword action, whose exile
-- Parun.Engine.Airbend writes as an Effect and this arm runs through the SAME
-- executor a card's own instructions run through. Nothing here reads which
-- effect that is.
--
-- MAY TARGET, Earthbend's arm one rule over: where the printing says "target"
-- (Airbending Lesson) the card declares the slot and CR 608.2b has already
-- narrowed `legal`, and where it does not (Avatar's Wrath's "airbend all other
-- creatures") the ObjectRef is a sweep. Neither is read here -- the exile
-- Parun.Engine.Airbend mints takes the reference unchanged. An illegal or
-- unfilled slot exiles nothing and the read-back below is empty.
--
-- The arrivals are read back off Binding.airbentObjects rather than off the
-- ObjectRef, which is CR 400.7: the ids the reference named are gone, and the
-- permission rule 701.65a states is about the incarnations the funnel minted in
-- exile. Read through Binding.slotObjects and not through ObjectRef.InSlot,
-- since the move binds ONE arrival as a target and several as a group, and only
-- that reader answers both shapes.
airbend :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
airbend runSubgame resolving source controller legal chosen ref = do
  let airbent g = Map.findWithDefault Set.empty Binding.airbentObjects (Binding.slotObjects (slotBindings resolving g))
  before <- State.gets airbent
  applyEffectWith runSubgame resolving source controller legal chosen (Airbend.exile ref)
  exiled <- State.gets airbent
  State.modify' (\g -> foldr (Airbend.grant source) g exiled)
  -- CR 701.65b: the airbend as a game event, and only when THIS exile moved
  -- one or more objects -- the binding accumulates across a resolution, so an
  -- earlier airbend's arrivals are not this one's. A regression fence: no
  -- card in data/cards/ airbends twice in one resolution.
  Monad.unless (Set.null (Set.difference exiled before)) (State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Airbend controller))))

-- CR 702.189a's mana through AddMana's own arm, then CR 702.189b's marker:
-- this is a firebending ability resolving, and `controller` is who controls it.
firebend :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ManaAddition.ManaAddition -> Game ()
firebend runSubgame resolving source controller legal chosen addition = do
  applyEffectWith runSubgame resolving source controller legal chosen (Effect.AddMana addition)
  State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Firebend controller)))

-- CR 701.47a: the resolving controller amasses; the keyword action is
-- Parun.Engine.Amass.amass's, and this arm evaluates only the printed N.
--
-- Targetless: no CR 608.2b legality to re-check.
amass :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Amass.Type.Amass -> Game ()
amass resolving source controller legal (Amass.Type.MkAmass quantity subtype mSlot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
  case Quantity.evaluateFor viewOf context gs resolving source quantity of
    Nothing -> pure () -- unevaluable quantity: no-op (the powerOf posture)
    Just n -> do
      chose <- Amass.amass controller source resolving subtype (Integer.toNaturalSaturating n)
      -- CR 701.47c: "the amassed Army" is the creature chosen, whether or not it
      -- received counters -- so this is bound off the choice and not off the
      -- counters, and an amass whose pool was empty (CR 701.47b) binds nothing.
      -- Onto `resolving`, which is bindSlot's contract: both resolution loops
      -- re-read the stack object's bindings before each effect (CR 608.2c), so
      -- the next clause sees it.
      Monad.forM_ ((,) <$> mSlot <*> chose) $ \(slot, army) -> State.modify' (bindSlot resolving slot army)

-- CR 701.68a: each player the PlayerRef names puts N -1/-1 counters on a
-- creature they control; the keyword action is Parun.Engine.Blight.blight's, and
-- rule 701.68b's optional reading is a cost (CR 118.12). MANDATORY here, so an
-- empty pool is CR 101.3's no-op. A reference naming nobody, or an illegal slot
-- (CR 608.2b), blights nothing. APNAP for the order (CR 101.4). Targetless: no
-- CR 608.2b legality to re-check.
--
-- Rule 101.4's last sentence -- "then the actions happen simultaneously" -- is
-- the Event.simultaneously bracket: every blighter's counters share one
-- Parun.Types.EventGroup, so a CR 603.2c batch condition watching placements
-- across permanents sees one trigger event and not one per seat.
--
-- The bracket does not touch the DECISION order, which stays the APNAP walk
-- above it: each seat is prompted in turn, from its own pool, knowing what the
-- seats before it chose (CR 101.4b). Rule 101.4's FIRST sentence -- all choices,
-- then the actions -- is honored as that order and no further: a seat's counters
-- are written to the board before the next seat is asked, and what the two
-- readings share is the event group rather than the moment of writing. The
-- difference is unobservable -- the quantity is evaluated off the pre-loop `gs`,
-- rule 701.68a's candidates are the asked seat's OWN creatures, CR 704.3 holds
-- state-based actions until a player would get priority, and no replacement in
-- data/cards reads a counter tally across permanents.
--
-- CR 701.68d's GameEvent.PlayerActed is written per blighter inside
-- Parun.Engine.Blight.blight, one per seat that actually blighted -- the
-- bracket groups them, which changes nothing here, PlayerActs not being a
-- CR 603.2c batch condition (Parun.Engine.Event.Trigger.batchScoped).
blight :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Blight.Type.Blight -> Game ()
blight resolving source controller legal (Blight.Type.MkBlight ref quantity mSlot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      named = playerRefPlayers legal resolving source controller gs ref
      blighters = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
  blightedCreatures <- Event.simultaneously . fmap Maybe.catMaybes . Monad.forM blighters $ \pid ->
    case evaluateForRecipient viewOf context gs resolving source pid quantity of
      Nothing -> pure Nothing -- unevaluable quantity: no-op (the powerOf posture)
      Just n -> Blight.blight (CounterCause.ByEffect pid) resolving (Integer.toNaturalSaturating n)
  -- CR 701.68c: "the blighted creature" is the object the blighting player chose
  -- to put the counters on, bound for a later clause of this same resolution to
  -- read (CR 608.2c) -- Grub, Notorious Auntie's token copy of it. Bound off the
  -- CHOICE and not off the counters, which is rule 701.68c's own wording: a
  -- blight of zero (CR 122.6), and one whose counters a replacement kept off,
  -- name a creature just the same.
  --
  -- ACROSS blighters, the Effect.Mill slot's one/many split: one chosen creature
  -- takes the single binding every singular reader can see, several take the
  -- group. A seat that could not blight (rule 701.68b) contributes nothing.
  bindObjects resolving mSlot blightedCreatures

-- CR 701.54a: the Ring tempts the resolving controller; the keyword action is
-- Parun.Engine.Ring.tempt's.
temptWithTheRing :: PlayerId -> Game ()
temptWithTheRing = Ring.tempt

openAttraction :: PlayerId -> Game ()
openAttraction = Attraction.open

-- The Unstable FAQ: the assembling permanent is the one the ObjectRef names
-- as this instruction is reached (CR 608.2c), or none where the player
-- assembles; Steamflogger Boss's row reads it.
assemble :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Maybe ObjectRef -> Game ()
assemble resolving source controller legal ref = do
  gs <- State.get
  let assembler = ref >>= \r -> Maybe.listToMaybe (Maybe.mapMaybe Recipient.objectOf (objectRefRecipients legal resolving controller source gs r))
  Contraption.assemble assembler controller

-- CR 701.31c: the cause is the planar die's exactly when this is CR 901.8's
-- planeswalking ability resolving.
planeswalk :: ObjectId -> PlayerId -> Game ()
planeswalk resolving controller = do
  gs <- State.get
  Planechase.planeswalk (if Planechase.isPlaneswalkingAbility resolving gs then PlaneswalkCause.PlanarDie else PlaneswalkCause.Instruction) controller

chaosEnsues :: Game ()
chaosEnsues = State.modify' (Event.recordEvent GameEvent.ChaosEnsued)

abandon :: ObjectId -> Game ()
abandon = Archenemy.abandon

-- CR 702.159b: the prize's actions are the effects after this one, so the
-- claim itself is only the event "whenever you claim the prize" reads.
claimPrize :: PlayerId -> Game ()
claimPrize controller = State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.ClaimPrize controller)))

-- CR 701.61a: the resolving controller forages; the keyword action is
-- Parun.Engine.Forage.forage's, prompts and all.
forage :: ObjectId -> PlayerId -> Game ()
forage resolving controller = Monad.void (Forage.forage controller resolving)

-- CR 701.36a: the resolving controller populates; the keyword action is
-- Parun.Engine.Populate.populate's, prompt and all.
populate :: ObjectId -> PlayerId -> Game ()
populate resolving controller = Populate.populate controller resolving

-- CR 701.56a: the resolving controller time travels, one procedure in
-- Parun.Engine.TimeTravel. Targetless: no CR 608.2b legality to re-check.
timeTravel :: ObjectId -> PlayerId -> Game ()
timeTravel resolving controller = TimeTravel.timeTravel controller resolving

-- CR 701.70a: the resolving controller recruits; the keyword action is
-- Parun.Engine.Recruit.recruit's, prompt and token alike.
recruit :: PlayerId -> Game ()
recruit = Recruit.recruit

-- CR 701.48a: the resolving controller learns; the keyword action is
-- Parun.Engine.Learn.learn's, prompts and all. `source` is the object the
-- card brought in from outside the game is credited to (CR 400.11c).
learn :: ObjectId -> ObjectId -> PlayerId -> Game ()
learn resolving source controller = Learn.learn controller resolving source

-- CR 701.58a: the named players each cloak the top card of their library; the
-- keyword action is Parun.Engine.Cloak.cloak's, listing and all. APNAP (CR
-- 608.2f) orders the several, which is Effect.Shuffle's posture and for its
-- reason: the order is a fact about the rules rather than about PlayerId's Ord.
cloak :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game ()
cloak resolving source controller legal ref = do
  gs <- State.get
  let named = Set.fromList (playerRefPlayers legal resolving source controller gs ref)
  Monad.mapM_ Cloak.cloak (filter (`Set.member` named) (Game.apnapOrder gs))

-- CR 701.62a: the named players each manifest dread, the keyword action being
-- Parun.Engine.ManifestDread.manifestDread's, choice and event alike. APNAP
-- orders the several, the Cloak arm's reason.
manifestDread :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game ()
manifestDread resolving source controller legal ref = do
  gs <- State.get
  let named = Set.fromList (playerRefPlayers legal resolving source controller gs ref)
  Monad.mapM_ (ManifestDread.manifestDread source) (filter (`Set.member` named) (Game.apnapOrder gs))

-- CR 701.49: the whole keyword action, which Parun.Engine.Dungeon owns.
venture :: PlayerId -> Maybe Subtype.Subtype -> Game ()
venture = Dungeon.venture

gainPlayerCounters :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerCounters.PlayerCounters -> Game ()
gainPlayerCounters resolving source controller legal (PlayerCounters.MkPlayerCounters ref kind quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      recipients = playerRefPlayers legal resolving source controller gs ref
  -- CR 122 / 107.14: the amount is read per recipient off the one pre-effect
  -- `gs`, then CR 122.6's funnel per recipient, so a counter-scaling
  -- replacement gets its CR 614 opportunity against each player's gain.
  Monad.forM_ recipients $ \pid ->
    case evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        | n > 0 -> Monad.void (Event.putPlayerCounters (CounterCause.ByEffect controller) pid kind (Integer.toNaturalSaturating n))
      _ -> pure ()

removePlayerCounters :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RemovePlayerCounters.RemovePlayerCounters -> Game ()
removePlayerCounters resolving source controller legal (RemovePlayerCounters.MkRemovePlayerCounters ref kind quantity mTally) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      recipients = playerRefPlayers legal resolving source controller gs ref
  Monad.forM_ recipients $ \pid ->
    case evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        | n > 0 ->
            -- CR 122: GainPlayerCounters' mirror, through no funnel for
            -- Effect.RemoveCounters' reason. The tally is what this player
            -- lost, Leeches' "that much".
            do
              lost <- State.state (Game.removePlayerCounters kind pid (Integer.toNaturalSaturating n))
              Monad.forM_ mTally $ \slot -> State.modify' (bindAmountSlot resolving source slot lost)
      _ -> pure ()

-- CR 107.14: "you may pay any amount of {E}". The payer is the resolving
-- controller (CR 109.5's "you"), the amount is theirs to name, and CR 118.3
-- caps it at the energy they actually have -- so unlike CR 601.2b's
-- announcement the bound is ENFORCED, and an answer above it is clamped rather
-- than trusted. Paying 0 is how the printed "may" is declined.
--
-- Through Parun.Engine.Cost's own reader and writer, so CR 107.14 has one
-- meaning here and in a CostComponent.PayEnergy payment.
--
-- The offer is skipped at a bound of 0, where CR 118.3 leaves 0 as the only
-- payable amount and there is nothing to decide. Proven by
-- Parun.CounterKeywordTriggerSpec's "a payer with no {E} is not asked how much
-- to pay", whose twin one {E} higher is asked.
payAnyEnergy :: ObjectId -> ObjectId -> PlayerId -> SlotName -> Game ()
payAnyEnergy resolving source controller slot = do
  gs <- State.get
  let have = Game.energyOf controller gs
  paid <-
    if have == 0
      then pure 0
      else do
        answer <- Game.choose (Prompt.ChoosePaidEnergy (Decide.deciderFor controller gs) controller resolving have)
        pure (min answer have)
  Cost.spendEnergy controller paid
  -- Bound onto this effect's SOURCE even when nothing was paid, Effect.Destroy's
  -- count for its reason: zero is an answer, where an unbound slot would leave a
  -- later clause's quantity unevaluable instead.
  State.modify' (bindAmountSlot resolving source slot paid)

-- CR 107.1c: "any number" is any natural, so the answer is taken as given. A
-- number past what a later instruction can act on is that instruction's CR
-- 609.3 shortfall, not this prompt's. Bound even at zero, PayAnyEnergy's
-- reason.
-- CR 608.2d: a player "can't choose an option that's illegal", so an answer
-- past the bound is clamped to it.
--
-- The chooser is askedChooser's one seat (CR 608.2c / 800.4g); a reference
-- naming none binds nothing (CR 101.3).
chooseNumber :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ChooseNumber.ChooseNumber -> Game ()
chooseNumber resolving source controller legal (ChooseNumber.MkChooseNumber slot upTo chooser) = do
  asked <- askedChooser resolving source controller legal chooser
  Monad.forM_ asked $ \pid -> do
    gs <- State.get
    answer <- Game.choose (Prompt.ChooseNumber (Decide.deciderFor pid gs) pid resolving 0 upTo)
    State.modify' (bindAmountSlot resolving source slot (maybe answer (min answer) upTo))

-- CR 701.26a: turn each named permanent sideways. The victims are enumerated
-- ONCE (CR 608.2f) and off the board as it stands before any of them is tapped,
-- so an illegal slot (CR 608.2b), a player recipient and a set that matched
-- nothing all tap nothing.
--
-- Through Parun.Engine.Event.tap rather than a direct write, which is what makes
-- each one a becomes-tapped event. Rule 701.26a's "only untapped permanents can
-- be tapped" lives in that funnel, and it earns its keep now that an event rides
-- on the write: the assignment was idempotent and the event is not.
--
-- The `tapped` slot binds what this turned sideways, in sweep order: a victim
-- that was untapped before and is tapped after, so one already tapped is not
-- "tapped this way". That exclusion is a regression fence, not a proved
-- behaviour: Master of the Wild Hunt's sweep names only untapped Wolves.
tap :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Tap.Tap -> Game ()
tap resolving source controller legal (Tap.MkTap ref mTapped) = do
  gs <- State.get
  let victims = ListUtils.nubOrd (objectRefObjects legal resolving controller source gs ref)
      tappedIn g oid = fmap Object.tapped (Game.lookupObject oid g) == Just TapState.Tapped
  -- One event group, CR 608.2f.
  Event.simultaneously (Monad.forM_ victims Event.tap)
  after <- State.get
  Monad.forM_ mTapped $ \slot -> do
    let turned = filter (\oid -> not (tappedIn gs oid) && tappedIn after oid) victims
    Monad.unless (null turned) (State.modify' (bindObjectsSlot resolving slot (Seq.fromList turned)))

-- CR 701.26b: rotate each named permanent back upright. The victims are
-- enumerated ONCE (CR 608.2f) and off the board as it stands before any of them
-- is untapped, so an illegal slot (CR 608.2b), a player recipient and a set
-- that matched nothing all untap nothing.
--
-- Through Parun.Engine.Event.untap rather than a direct write, Effect.Tap's
-- reason one rule clause over: rule 701.26b's "only tapped permanents can be
-- untapped" lives in that funnel, and CR 122.1d's replacement is offered the
-- event there.
--
-- Through askingObjects, so CR 608.2d's "untap up to two lands" (Teferi,
-- Hero of Dominaria) is asked rather than read.
untap :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
untap resolving source controller legal chosen ref = do
  victims <- askingObjects resolving source controller legal chosen ref
  Monad.forM_ victims Event.untap

detain :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
detain resolving source controller legal ref =
  State.modify' $ \gs ->
    -- CR 701.35a: detain each named permanent until the next turn of this
    -- resolution's `controller` (CR 109.5), sampled once, since the sweep that
    -- ends the detain (Parun.Engine.Expiry.dropAtTurnOf) has no resolution left
    -- to read it off. The victims are enumerated ONCE (CR 608.2f). Nothing is
    -- stored anywhere but on the victim, so an already-detained permanent is
    -- detained again with no count kept -- see Object.detainedUntil.
    foldr (Detain.detain controller) gs (objectRefObjects legal resolving controller source gs ref)

goad :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
goad resolving source controller legal ref =
  State.modify' $ \gs ->
    -- CR 701.15a: goad each named permanent until the next turn of this
    -- resolution's `controller` (CR 109.5), sampled once, for the reason
    -- Effect.Detain samples it. The victims are enumerated ONCE (CR 608.2f).
    -- An already-goaded permanent goaded again by the same player keeps one
    -- entry, which is CR 701.15d -- see Object.goadedBy.
    foldr (Goad.goad controller) gs (objectRefObjects legal resolving controller source gs ref)

pair :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
pair resolving source controller legal chosen ref = do
  -- CR 702.95a: pair this effect's SOURCE with the permanent the ObjectRef
  -- names, under this resolution's controller (CR 109.5). Exactly one partner,
  -- rule 702.95a naming one creature -- a ref that named none, or several,
  -- pairs nothing, which is CR 101.3. CR 702.95c's recheck and CR 702.95d's
  -- limit are Soulbond.pair's, read off the board as the effect applies rather
  -- than off anything the trigger captured.
  --
  -- The CHOSEN ref goes through askingObjects and not the pure sweep: CR
  -- 608.2d's choice is an ask, which objectRefObjects cannot make.
  partners <- askingObjects resolving source controller legal chosen ref
  State.modify' $ \gs -> case partners of
    [partner] -> Soulbond.pair controller source partner gs
    _ -> gs

doesNotUntapNext :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> DoesNotUntapNext.DoesNotUntapNext -> Game ()
doesNotUntapNext resolving source controller legal payload =
  State.modify' $ \gs ->
    -- CR 502.3's untap prohibition, as a one-shot; the victims are enumerated
    -- ONCE (CR 608.2f). No duration is stored: each victim carries how many of
    -- its controller's untap steps are still to skip, and Engine.untapAll
    -- counts one off at each. The LARGER count is kept, never the sum: every
    -- prohibition runs from the next step, so two over the same step expire
    -- together (CR 701.43b says it of exert).
    let steps = DoesNotUntapNext.steps payload
        mark o = o {Object.doesNotUntapFor = max steps (Object.doesNotUntapFor o)}
     in gs
          { GameState.objects =
              foldr (Map.adjust mark) (GameState.objects gs) (objectRefObjects legal resolving controller source gs (DoesNotUntapNext.ref payload))
          }

transform :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
transform resolving source controller legal chosen = turnPermanentsOver legal chosen resolving controller source

-- CR 701.28a routes a convert through rules 701.27a-f unchanged, so it is the
-- SAME call and not a similar one. The two opcodes stay distinct in the card
-- data (Parun.Types.Effect.Convert) and identical in behaviour here.
convert :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
convert resolving source controller legal chosen = turnPermanentsOver legal chosen resolving controller source

flipArm :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
flipArm resolving source controller legal ref =
  State.modify' $ \gs ->
    -- CR 710.2: flip each named permanent, so its alternative characteristics
    -- apply from now on. The victims are enumerated ONCE (CR 608.2f), off the
    -- board as it stands before any of them flips -- which changes nothing
    -- here, no permanent's flipped status being visible to another's gate, but
    -- is Effect.Tap's discipline and costs nothing to keep.
    --
    -- Not turnPermanentsOver's shape, though both change what a permanent
    -- shows. CR 701.27f's already-turned gate belongs to a TURN and has no
    -- flip counterpart -- CR 710.4 makes flipping one-way, so a second flip is
    -- an assignment of the value already there rather than something a rule
    -- must ignore -- and CR 613.7 grants a flip no new timestamp, so there is
    -- no CR 613.7m ordering for the batch to ask its controllers about.
    --
    -- Through Game.flipPermanent, which carries CR 110.5d's battlefield gate
    -- and the layout classification, so an instruction naming a permanent with
    -- no alternative characteristics simply does nothing.
    foldr Game.flipPermanent gs (objectRefObjects legal resolving controller source gs ref)

meld :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Meld.Meld Card.Type.Card -> Game ()
meld resolving source controller legal (Meld.MkMeld ref resultCard) = do
  gs <- State.get
  -- An ordinary read of the ref (CR 608.2c), not a question: the cards were
  -- named by the ability that melds -- for the pool's only pair, the slot its
  -- own "exile them" bound (CR 400.7j) -- so there is nothing here to ask. The
  -- one choice this card makes is WHICH counterpart to exile, and it is made an
  -- instruction earlier.
  --
  -- Event.meld is the whole of CR 701.42a, gate included: it refuses (CR
  -- 701.42b) by writing nothing, which is CR 701.42c's "they stay in their
  -- current zone" -- the cards are wherever the exile left them, and this
  -- resolution simply had no effect. Nothing is bound and no slot is filled: no
  -- printing names the melded permanent later in its own instruction list.
  Monad.void (Event.meld controller (objectRefObjects legal resolving controller source gs ref) resultCard)

phaseOut :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
phaseOut resolving source controller legal ref =
  State.modify' $ \gs ->
    -- CR 702.26b: each named permanent phases out; the victims are enumerated
    -- ONCE (CR 608.2f). The whole set goes to Phasing.phaseOutSet in one call,
    -- because CR 702.26g and CR 702.26h both ask whether a permanent's HOST is
    -- leaving in this same event, which per-victim calls could not see.
    --
    -- Nothing about the row is read off `controller`: rule 702.26a schedules
    -- the return by who controlled IT, and `controller` is only phaseOutSet's
    -- fallback for a permanent the projection can no longer place.
    Phasing.phaseOutSet controller (Set.fromList (objectRefObjects legal resolving controller source gs ref)) gs

-- CR 500.8: add the phases, directly after the phase this is resolving in.
-- Turn.splicePhases is handed GameState.phase because that is NOT the head of
-- `remaining` when the resolving phase still has steps to come; CR 511.3 bounds
-- the phase, and Turn.thisPhase is where that lives.
addPhases :: [ExtraPhase.ExtraPhase] -> Game ()
addPhases extras =
  State.modify' $ \gs ->
    gs {GameState.remaining = Turn.splicePhases (GameState.phase gs) extras (GameState.remaining gs)}

-- CR 724.1: end the turn (Time Stop). Rule 724.1's six steps, in its own order,
-- and deliberately NOT the CR 608 process the fold around this is running.
endTurn :: Game Result -> Game ()
endTurn runSubgame = do
  -- CR 724.1a: an ability that triggered before this process began but is not
  -- yet on the stack ceases to exist. There is no pending queue to flush -- a
  -- pending trigger is DERIVED from GameState.events behind the CR 117.5
  -- watermark -- so this is a watermark bump, which is also what makes rule
  -- 724.1f's exception fall out: everything recorded after this line is an
  -- ability that triggered DURING the process, and stays unscanned until the
  -- cleanup step settles. Ultima over a Doomed Traveler proves it
  -- (Parun.TurnSpec, "CR 724.1a a trigger pending when the turn ends ceases to
  -- exist").
  State.modify' $ \gs ->
    gs
      { GameState.scannedThrough = Natural.length (GameState.events gs),
        GameState.boardAfterEvent = Map.empty,
        GameState.battlefieldWhenTriggered = Map.empty
      }
  -- CR 724.1b: exile every object on the stack, INCLUDING the one that is
  -- resolving -- which is still on GameState.stack, Stack.resolveTopWith
  -- leaving it there until CR 608.2n moves it. A real zone change, so an
  -- ability that triggers off one is CR 724.1f's.
  --
  -- Rule 724.1b's second sentence -- an object not represented by a card ceases
  -- to exist at the next check -- is taken HERE for an ability rather than at
  -- CR 724.1c, and the two are indistinguishable: nothing happens between the
  -- exile and that check, and Game.cease is already what CR 608.2n, CR 603.3c
  -- and CR 701.6a use for an ability, which is not a card and so has no zone to
  -- arrive in (CR 400.7 mints nothing). A token, and a copy of a spell, DO go
  -- through the exile, Parun.Engine.Sba implementing CR 704.5d and CR 704.5e for
  -- them.
  --
  -- finishSpell still runs when this fold returns, and is a no-op for it: CR
  -- 400.7 minted a fresh incarnation in exile, so changeZone's lookup of the
  -- old id finds nothing and the spell stays exiled rather than reaching a
  -- graveyard.
  onStack <- State.gets GameState.stack
  Foldable.traverse_ exileOrCease onStack
  -- CR 724.1c: check state-based actions, granting no priority and putting no
  -- triggered ability on the stack -- so Parun.Engine.Sba's own pass and not
  -- Engine.performSettle, which places triggers. (Engine is unreachable from
  -- here in any case: Engine imports Stack imports Resolve.)
  --
  -- Repeated to a fixpoint on CR 704.3's authority -- "if any state-based
  -- actions are performed as a result of a check, the check is repeated" -- and
  -- one pass does not reach it: CR 704.5m's Aura falls off only on the pass
  -- after the creature it enchanted died. Terminates because the flag is False
  -- as soon as a pass performs nothing.
  -- A loss the pass replaced runs its effects inside the pass
  -- (runDamageRewriteEffect), and a pass that replaces it forever is CR
  -- 104.4b's draw (Departure.checkMandatoryLoop).
  --
  -- Not implemented: keeping the board before each pass, which CR 603.8
  -- reads, for the next settle, here and in the EndCombatPhase arm (#5359).
  let checkToFixpoint passes = do
        begun <- State.gets GameState.lastChoice
        performed <- Sba.performStateBasedActions (runDamageRewriteEffect runSubgame) []
        runReplacementEffects runSubgame
        passed <- Departure.passesSince begun passes
        Departure.checkMandatoryLoop passed
        ended <- State.gets (Maybe.isJust . GameState.result)
        Monad.when (performed && not ended) (checkToFixpoint passed)
  checkToFixpoint 0
  -- CR 724.1d: the current phase and/or step ends; creatures and planeswalkers
  -- leave combat if this happened during one; the game skips straight to the
  -- cleanup step, or to a NEW cleanup step if this IS one.
  --
  -- What ends the step is Engine.runStepThatBegan, which resumes after the
  -- signal below stops the priority round and runs CR 500.5's expiries and CR
  -- 703.4q's mana emptying exactly as it would for a step that ended by
  -- itself. Nothing of that is duplicated here.
  --
  -- The PHASE-scoped half of CR 500.5 is taken here and not there, on rule
  -- 724.1d's "the current phase and/or step ends": Turn.phaseEndingAt answers
  -- from the last step alone, and the step this ends is not it, so an "until
  -- end of combat" effect would otherwise outlive a turn ended during combat.
  -- The phase does NOT end when the jump stays inside it -- CR 512.1 puts the
  -- cleanup step in the ending phase, so ending the turn during the end step
  -- leaves that phase still under way.
  State.modify' $ \gs ->
    let phase = GameState.phase gs
        cleared = case phase of
          Phase.Combat _ -> Combat.clearCombat gs
          _ -> gs
        -- Both sweeps, for the same reason: a mana unit's "until end of combat"
        -- retention carries no Expiry, so Expiry.dropAtEndOf cannot reach it
        -- (CR 500.5a). The mana itself is taken by the CR 500.5 sweep this
        -- step's own end runs in Engine.runStepThatBegan, once this has made
        -- the units ordinary.
        expired = case phase of
          Phase.Ending _ -> cleared
          _ -> maybe cleared (\ending -> Mana.endRetentionAtEndOf ending (Expiry.dropAtEndOf ending cleared)) (Turn.wholePhaseOf phase)
        jumped = case phase of
          Phase.Ending EndingStep.Cleanup -> Turn.spliceExtraCleanup (GameState.remaining gs)
          _ -> Turn.jumpToCleanup (GameState.remaining gs)
     in expired {GameState.remaining = jumped}
  -- CR 724.1f: no player gets priority during this process. Engine.priorityLoop
  -- reads this and returns without settling and without granting another round,
  -- so the exiles above stay unscanned until the cleanup step's own CR 514.3a
  -- settle puts them on the stack. Engine.runStep lowers it there.
  State.modify' (\gs -> gs {GameState.endTurnSignal = EndTurnSignal.Ended})

-- CR 724.2: end the combat phase (Mandate of Peace). Rule 724.2's seven steps,
-- in its own order, and deliberately NOT the CR 608 process around it. The arm
-- above is its sibling and not its implementation: the two agree on 724.2a-c
-- and differ on what 724.2d leaves at the head of the schedule.
endCombatPhase :: Game Result -> Game ()
endCombatPhase runSubgame = do
  phase <- State.gets GameState.phase
  case phase of
    -- CR 724.2g: attempted at a time that is not a combat phase, nothing
    -- happens -- not even the exile of the stack, since rule 724.2's steps are
    -- the whole of what "ends the combat phase" does. No CAST reaches it today:
    -- Mandate of Peace's own rider admits only a combat phase, and nothing
    -- between the cast and the resolution can leave one, this being the only
    -- card that ends a combat phase. The guard is rule 724.2g's own sentence
    -- rather than a defence against a board parun can build, and
    -- Parun.TurnSpec's CR 724.2g case reaches it by applying the effect
    -- directly.
    Phase.Combat _ -> do
      -- CR 724.2a, exactly as CR 724.1a: a watermark bump rather than a queue
      -- flush, which is also what makes 724.2f's exception fall out. UNOBSERVED
      -- for the same reason the arm above says: resolution follows a settle, so
      -- nothing is pending here.
      State.modify' $ \gs ->
        gs
          { GameState.scannedThrough = Natural.length (GameState.events gs),
            GameState.boardAfterEvent = Map.empty,
            GameState.battlefieldWhenTriggered = Map.empty
          }
      -- CR 724.2b: exile every object on the stack, the resolving one included.
      -- Shared with the arm above down to the CR 400.7 detail that leaves
      -- finishSpell a no-op afterwards.
      onStack <- State.gets GameState.stack
      Foldable.traverse_ exileOrCease onStack
      -- CR 724.2c: check state-based actions, granting no priority and putting
      -- no triggered ability on the stack. To a fixpoint on CR 704.3's
      -- authority, as above.
      let checkToFixpoint passes = do
            begun <- State.gets GameState.lastChoice
            performed <- Sba.performStateBasedActions (runDamageRewriteEffect runSubgame) []
            runReplacementEffects runSubgame
            passed <- Departure.passesSince begun passes
            Departure.checkMandatoryLoop passed
            ended <- State.gets (Maybe.isJust . GameState.result)
            Monad.when (performed && not ended) (checkToFixpoint passed)
      checkToFixpoint 0
      -- CR 724.2d, in the rule's own sentence order: the phase ends, creatures
      -- and planeswalkers leave combat, "until end of combat" effects expire,
      -- and the game skips the steps between here and the next phase.
      --
      -- The expiry is this rule's, not CR 500.5's through
      -- Engine.runStepThatBegan: that sweep asks Turn.phaseEndingAt, which
      -- answers from the phase's last step, and CR 724.2e is precisely the
      -- claim that the end of combat step never runs. EQUALITY on
      -- PhaseSelector.CombatPhase, so an "until end of turn" effect installed
      -- by the same card survives (Expiry.dropAtEndOf says why).
      --
      -- Where the game lands is whatever `remaining` holds after this phase --
      -- CR 724.2d's "usually the postcombat main phase", and a CR 500.8 extra
      -- combat phase later in the turn is untouched, Turn.dropRestOfPhase being
      -- positional.
      State.modify' $ \gs ->
        let cleared = Combat.clearCombat gs
            skipped = cleared {GameState.remaining = Turn.dropRestOfPhase phase (GameState.remaining gs)}
         in -- Both sweeps, the CR 724.1d arm's reason above: an "until end of
            -- combat" mana retention rides the UNIT and carries no Expiry, so
            -- the phase ending here has to end it too. The mana goes with this
            -- step's own CR 500.5 sweep in Engine.runStepThatBegan.
            Mana.endRetentionAtEndOf PhaseSelector.CombatPhase (Expiry.dropAtEndOf PhaseSelector.CombatPhase skipped)
      -- CR 724.2f: no player gets priority during this process. The SAME signal
      -- CR 724.1f raises, because the two rules want the same thing of
      -- Engine.priorityLoop -- return without settling and without granting
      -- another round -- and differ only in which step Engine.runStep lowers it
      -- at. CR 724.1d leaves the cleanup step at the head of the schedule and
      -- CR 724.2d the following phase, so "the abilities that triggered during
      -- this process are put onto the stack there" is one mechanism, not two.
      State.modify' (\gs -> gs {GameState.endTurnSignal = EndTurnSignal.Ended})
    _ -> pure ()

-- Exactly one new controller or nothing: a slot CR 608.2b emptied names
-- nobody to give the object to.
gainControl :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GainControl.GainControl -> Game ()
gainControl resolving source controller legal (GainControl.MkGainControl duration ref to) =
  State.modify' $ \gs -> case playerRefPlayers legal resolving source controller gs to of
    [recipient] -> installControl legal resolving controller source recipient duration ref gs
    _ -> gs

-- CR 701.12b: each of the two permanents goes to the other's controller,
-- simultaneously. TWO stored effects, because Modification.SetController names
-- one controller, and both read the PROJECTED controller off the same pre-swap
-- `gs`, which is what makes the two halves simultaneous rather than a chain.
--
-- CR 302.6 re-Sicks both, GainControl's arm above for the same reason; control
-- provably moves for each here, so the per-object question that arm asks is
-- already answered by the guard.
--
-- CR 800.4b is not asked: a player who has left the game controls nothing, CR
-- 800.4a's exile having already run, so neither new controller can be one.
exchangeControl :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ControlSides.ControlSides -> Game ()
exchangeControl resolving source controller legal sides =
  State.modify' $ \gs ->
    let twoSides = case sides of
          -- A target slot's CR 608.2b-legal recipients, or the group earlier
          -- instructions of this resolution bound (CR 608.2c).
          ControlSides.WithinSlot slot -> case Set.toList (Map.findWithDefault Set.empty slot (Binding.objectsBySlot legal (slotBindings resolving gs))) of
            [one, two] -> [one, two]
            _ -> []
          -- CR 113.7's source object, found through the funnel
          -- Filter.IsSource reads it by rather than off
          -- Object.source: a permanent that is a COPY of Avarice Totem is the
          -- side, not the card. A source no longer on the battlefield matches
          -- nothing and so is no side at all, which is CR 701.12a again.
          --
          -- A slot naming the source itself needs no guard here: both sides
          -- are then the one permanent, so the controller test below is what
          -- CR 701.12b's "controlled by the same player" says it is.
          ControlSides.WithSource slot ->
            case (battlefieldMatching legal resolving controller source gs Filter.Type.IsSource, legalOne slot legal >>= Recipient.objectOf) of
              ([self], Just other) -> [self, other]
              _ -> []
          ControlSides.BetweenSlots (ControlSlots.MkControlSlots one two) ->
            case (legalOne one legal >>= Recipient.objectOf, legalOne two legal >>= Recipient.objectOf) of
              (Just this, Just that) -> [this, that]
              _ -> []
     in case twoSides of
          [one, two] -> case (Projection.controllerOf one gs, Projection.controllerOf two gs) of
            -- CR 701.12b: controlled by the same player, the exchange effect
            -- does nothing. Parun.BoardEffectSpec's Switcheroo group is the
            -- proof.
            (Just first, Just second)
              | first /= second ->
                  let (ts, gs1) = Game.freshTimestamp gs
                      -- CR 611.2c / 613.1b: one layer-2 effect per side, both
                      -- at the one timestamp -- they affect disjoint objects,
                      -- so no CR 613.7 order between them is observable.
                      swap oid pid =
                        ContinuousEffect.MkContinuousEffect
                          { ContinuousEffect.source = source,
                            ContinuousEffect.timestamp = ts,
                            -- Indefinite: Expiry.arm's Duration.Indefinite
                            -- answer, and the printed reminder ("This effect
                            -- lasts indefinitely", Legerdemain).
                            ContinuousEffect.expiry = Expiry.Type.Never,
                            ContinuousEffect.modification = Modification.SetController pid,
                            ContinuousEffect.affected = Affected.TheseObjects (Set.singleton oid)
                          }
                      sicken o = o {Object.sickness = Sickness.Sick}
                   in gs1
                        { GameState.continuousEffects = swap one second : swap two first : GameState.continuousEffects gs1,
                          GameState.objects = foldr (Map.adjust sicken) (GameState.objects gs1) [one, two]
                        }
            _ -> gs
          -- CR 701.12a: if the entire exchange can't be completed, no part of
          -- it occurs -- so a slot CR 608.2b has emptied to fewer than two
          -- objects, or one holding a player, changes nothing.
          _ -> gs

takeExtraTurnArm :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> TakeExtraTurn.TakeExtraTurn -> Game ()
takeExtraTurnArm resolving source controller legal takeExtraTurn = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- How many extra turns each named player is given, read ONCE: Ral
      -- Zarek's "for each coin that comes up heads" is the tally the flip
      -- before it bound. CR 107.2's posture for a quantity that cannot be
      -- evaluated: no turns at all.
      turns = Integer.toNaturalSaturating (Maybe.fromMaybe 0 (Quantity.evaluateFor viewOf context gs resolving source (TakeExtraTurn.count takeExtraTurn)))
      named = playerRefPlayers legal resolving source controller gs (TakeExtraTurn.player takeExtraTurn)
      -- CR 500.7: extra turns are added one at a time in APNAP order (CR
      -- 101.4). apnapOrder supplies the ORDER and `named` the MEMBERSHIP, so a
      -- departed player gets no turn; one named through a TARGET slot can still
      -- get an entry, and CR 800.4k catches it at the handoff.
      --
      -- Observable: APNAP order decides which of two players takes their extra
      -- turn first.
      --
      -- CR 805.8: under the shared team turns option one effect giving several
      -- players on a team the same turn gives that team one, so the team's
      -- first player in APNAP order takes the entry, as Effect.SkipPhase's
      -- arm keeps one skip. Proved by Parun.TeamSpec's "CR 805.8 one effect
      -- gives a team one extra turn".
      takers = List.foldl' (\kept pid -> if any (Turn.sharesTurn gs pid) kept then kept else kept <> [pid]) [] (filter (\pid -> List.elem pid named) (Game.apnapOrder gs))
  -- CR 500.7: the most recently created turn is taken first, so each taker is
  -- pushed onto the head and the last pushed is the first popped -- a stack.
  --
  -- CR 500.11 / 113.7: the skips ride ALONG on each entry, naming that turn and
  -- no other; Engine.takeNextTurn installs them as the turn begins (see
  -- Parun.Types.ExtraTurn).
  --
  -- CR 500.7: "if a player is given multiple extra turns, the extra turns are
  -- added one at a time" -- `turns` rounds, each pushing one turn per taker in
  -- APNAP order. Whether the rounds nest inside the APNAP walk or around it is
  -- observable only for an effect giving SEVERAL players SEVERAL turns each,
  -- which no card in data/cards/ prints; Ral Zarek names one player.
  --
  -- Each turn is stamped as it is created, the identity Onset.FromThatExtraTurn
  -- names it by.
  let push g pid =
        let (stamp, g1) = Game.freshTimestamp g
            entry = ExtraTurn.MkExtraTurn {ExtraTurn.taker = pid, ExtraTurn.source = source, ExtraTurn.skipped = TakeExtraTurn.skips takeExtraTurn, ExtraTurn.createdAt = stamp}
         in g1 {GameState.extraTurns = entry : GameState.extraTurns g1}
      pushRound g = List.foldl' push g takers
  State.modify' (\g -> List.foldl' (\acc _ -> pushRound acc) g [1 .. turns])
