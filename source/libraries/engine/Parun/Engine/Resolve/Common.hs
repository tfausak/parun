-- The helpers applyOneEffect's arms share that never recurse into resolving an
-- effect, split out of Parun.Engine.Resolve.Effect so the arm modules compile
-- against them in parallel.
module Parun.Engine.Resolve.Common where

import Control.Applicative ((<|>))
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Archenemy as Archenemy
import qualified Parun.Engine.Attach as Attach
import qualified Parun.Engine.Attraction as Attraction
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Cast as Cast
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Count as Count
import qualified Parun.Engine.CounterRestriction as CounterRestriction
import qualified Parun.Engine.Damage as Damage
import qualified Parun.Engine.Daytime as Daytime
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Expiry as Expiry
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Forage as Forage
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Engine.Phasing as Phasing
import qualified Parun.Engine.Plane as Plane
import qualified Parun.Engine.Planechase as Planechase
import qualified Parun.Engine.Players as Players
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.Rewrite as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Replacement as Replacement
import Parun.Engine.Resolve.Slots (boundSlots, chosenCandidates, effectContext, effectObjectRefs, effectPlayerRefs, effectViewOf, graveyardCardsOf, handCardsOf, legalMany, legalOne, libraryCardsOf, matchingFromAmong, objectRefObjects, playerRefPlayers, playerRefSlots, replacementRowSlots, resolutionReads, resolvingAbilityName, resolvingKind, slotBindings, slotGroup)
import qualified Parun.Engine.Restamp as Restamp
import qualified Parun.Engine.Room as Room
import qualified Parun.Engine.SourceContext as SourceContext
import qualified Parun.Engine.Star as Star
import qualified Parun.Engine.Sticker as Sticker
import qualified Parun.Engine.Target as Target
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Ante as Ante
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.AnyNumberOf as AnyNumberOf
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.ArrangedArrival as ArrangedArrival
import qualified Parun.Types.Ballot as Ballot
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CarryOver as CarryOver
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.ChoosePermanents as ChoosePermanents
import qualified Parun.Types.Chooser as Chooser
import qualified Parun.Types.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Types.ChosenCardInGraveyard as ChosenCardInGraveyard
import qualified Parun.Types.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.CostBasis as CostBasis
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.CounterCause as CounterCause
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePattern as DamagePattern
import qualified Parun.Types.DamageR as DamageR
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.DelayedTrigger as DelayedTrigger
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.DifferentIn as DifferentIn
import qualified Parun.Types.Discard as Discard
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.Duration as Duration
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntryAttack as EntryAttack
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.ExchangeCardZones as ExchangeCardZones
import qualified Parun.Types.ExileLink as ExileLink
import qualified Parun.Types.ExilePlayPermission as ExilePlayPermission
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.FromAnywhere as FromAnywhere
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameSettings as GameSettings
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Guess as Guess
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.InherentTriggerSource as InherentTriggerSource
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.LookAt as LookAt
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.ManaSpending as ManaSpending
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.Modal as Modal.Type
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.MoveCounters as MoveCounters
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.MovedKinds as MovedKinds
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ObjectRef (ObjectRef)
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.PayBranch as PayBranch
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation
import qualified Parun.Types.PayOffer as PayOffer
import qualified Parun.Types.PaymentDecision as PaymentDecision
import qualified Parun.Types.PaymentSubject as PaymentSubject
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentAction as PermanentAction
import qualified Parun.Types.PermanentWasSacrificed as PermanentWasSacrificed
import qualified Parun.Types.Player as Player
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerChoice as PlayerChoice
import qualified Parun.Types.PlayerControl as PlayerControl
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerInstruction as PlayerInstruction
import Parun.Types.PlayerRef (PlayerRef)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerSacrifices as PlayerSacrifices
import qualified Parun.Types.PlayersWho as PlayersWho
import qualified Parun.Types.Power as Power
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.ProposedEvent as ProposedEvent
import qualified Parun.Types.PutSticker as PutSticker
import qualified Parun.Types.Quantity as Quantity.Type
import qualified Parun.Types.RandomCardInGraveyard as RandomCardInGraveyard
import qualified Parun.Types.RandomCardInHand as RandomCardInHand
import qualified Parun.Types.RandomCardInLibrary as RandomCardInLibrary
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.RemovalCount as RemovalCount
import qualified Parun.Types.RemoveCounters as RemoveCounters
import qualified Parun.Types.RemoveCountersAmong as RemoveCountersAmong
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import Parun.Types.Result (Result)
import qualified Parun.Types.Result as Result
import qualified Parun.Types.Reveal as Reveal
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.SearchDestination as SearchDestination
import qualified Parun.Types.SetHalfLocked as SetHalfLocked
import qualified Parun.Types.Sickness as Sickness
import qualified Parun.Types.SideDeck as SideDeck
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.Source as Source
import qualified Parun.Types.SpendTrigger as SpendTrigger
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.StickerRef as StickerRef
import qualified Parun.Types.StoredResult as StoredResult
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Tap as Tap
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.Toughness as Toughness
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TriggeredAbilitySource as TriggeredAbilitySource
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Voted as Voted
import qualified Parun.Types.WhichCounters as WhichCounters
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange
import qualified Parun.Types.ZoneScope as ZoneScope

-- CR 603.7c / 608.2c: bind the objects an instruction made, moved, drew or
-- chose under the slot the effect names, so a later effect of this resolution
-- or a delayed ability it arms can name them.
--
-- For Create and CreateCopy, EVERY token minted, whatever the card's printed
-- count: the rulings on Anointed Procession and Flamerush Rider both say a
-- rider the creating effect attached applies to each token CR 614.16
-- multiplied the count into, and Queen Allenal of Ruadach's say the same of a
-- token a replacement APPENDED. So the word the card used -- "it" or "those
-- tokens" -- changes nothing here and the printed quantity is not consulted.
--
-- The singular shape is kept for the single token, because that is the shape
-- every reader sees: Resolve.slotOne and legalOne read Binding.targets, which a
-- group never fills. A reader that must reduce a group to one object does it
-- itself -- Effect.Attach through Attach.arbitrate, CR 301.5c.
bindObjects :: ObjectId -> Maybe SlotName -> [ObjectId] -> Game ()
bindObjects resolving mSlot named = case (mSlot, named) of
  (Nothing, _) -> pure ()
  -- Nothing was named, so no slot names an empty set: for Create an
  -- unevaluable or non-positive count, a creator reference naming nobody (CR
  -- 101.3), a creator who has left the game (CR 800.4b), or CR 111.5's
  -- prohibited token, which createTokens refuses to mint at all.
  (Just _, []) -> pure ()
  -- One object is the whole of what the instruction named.
  (Just slot, [only]) -> State.modify' (bindSlot resolving slot only)
  -- Several take the group.
  (Just slot, several) -> State.modify' (bindObjectsSlot resolving slot (Seq.fromList several))

-- CR 111.3: the values the creating effect defines become the token's text, so a
-- computed power or toughness is settled here and stamped as a literal. Left as a
-- quantity it would be re-read on every projection, and GameState.events is
-- cleared at the turn handoff -- the token would have no P/T next turn and die to
-- a state-based action. P/T is the whole of it: the only printed characteristics
-- a Face holds as a Quantity.
--
-- A box holding CR 208.2's STAR is left standing, so Projection.seedCharacteristicPT
-- still has a star to substitute the token's characteristic-defining ability into
-- at layer 7a. Everything else is settled even when it cannot be evaluated, on CR
-- 208.2a's terms (Quantity.determineWith: an undeterminable number is 0, including
-- inside a calculation) -- Miming Slime with no creatures makes a 0/0 Ooze, which
-- CR 704.5f puts away unless something is raising its toughness. Left standing it
-- would instead be a board-reading box on a permanent, which is not a thing CR
-- 208 allows a token to have.
--
-- The star half is proved by the scenario
-- consuming-blob-ooze-token-keeps-its-star-plus-one-box: Consuming Blob's Ooze
-- token prints a *+1 toughness, and settling that box makes it a 3/1.
bakeTokenCharacteristics :: (Quantity.Type.Quantity -> Maybe Integer) -> Card.Type.Card -> Card.Type.Card
bakeTokenCharacteristics eval card =
  let bake quantity =
        if Star.containsStar quantity
          then quantity
          else Quantity.Type.Literal (Quantity.determineWith eval quantity)
      bakeFace face =
        face
          { Face.power = fmap (Power.MkPower . bake . Power.unwrap) (Face.power face),
            Face.toughness = fmap (Toughness.MkToughness . bake . Toughness.unwrap) (Face.toughness face)
          }
   in card {Card.Type.faces = fmap bakeFace (Card.Type.faces card)}

-- CR 608.2b: a target can stop being legal because an effect changed the spell's
-- text, so the re-check measures the spell's own slots with CR 612.1's changes
-- applied. Off the face rather than off modesOf, which has no room for CR
-- 303.4a's enchant slot. Both readers -- the fizzle test and resolveSpellWith's
-- per-effect skip -- go through this, so they cannot disagree.
targetSlotsOf :: Object.Object -> ObjectId -> GameState -> Face.Face Card.Type.Card -> Map.Map SlotName TargetSlot.TargetSlot
targetSlotsOf obj oid gs face =
  if Keyword.castOverloaded (Object.castUsing obj)
    then
      -- CR 702.96b: a spell cast for its overload cost "won't require any
      -- targets", so CR 608.2b has nothing to re-read. The announcement dropped
      -- the same slots (Parun.Engine.Cast.castProposed), so this is agreement
      -- rather than a second reading.
      --
      -- A REGRESSION FENCE rather than a proved line: the announcement leaves
      -- the slot unbound, so every reader here already answers the same with the
      -- printed map -- mutating this arm away leaves Parun.CastSpec's Overload
      -- group green. stackTargetSlots' copy road (CR 707.10d's retarget) is what
      -- would observe it, and no test copies an overloaded spell.
      Map.empty
    else
      -- CR 608.2b: a "for each opponent" slot is re-judged per copy it bound.
      Target.boundCopies (Map.keysSet (Object.bindings obj)) $
        fmap
          (Projection.rewriteTargetSlot (Projection.textChangesAffecting oid gs))
          -- CR 303.4a's slot comes off the PROJECTION and not off `face`, which is
          -- the only reading that sees a granted enchant ability -- CR 702.103b
          -- gives a spell cast bestowed one, and its printed face declares none. A
          -- printed Aura's projection is seeded from that same printed list, so
          -- this is the wider read rather than a different one.
          --
          -- CR 702.47d's slots ride beside the face's: the spliced text is the
          -- spell's own (CR 702.47c), so its targets are re-checked with the rest.
          (Map.union (Card.modesTargetSlotsGiven (Projection.enchantOf oid gs) (Object.mutating obj) (Binding.modesOf (Object.bindings obj)) face) (Game.splicedTargetSlots obj gs))

-- CR 608.2c: one clause's instructions, in written order, carrying the one thing
-- a later instruction can ask about an earlier one -- whether it HAPPENED. CR
-- 701.28e is what makes that question observable: an instruction to convert a
-- permanent that has already converted "is ignored", so a CR 603.12 reflexive
-- ability armed after it hangs off a trigger event that never occurred, and rule
-- 603.12 creates it only "based on whether the trigger event or events occurred".
--
-- WHAT ANSWERS IT is the act rather than the opcode: an instruction HAPPENED
-- when it recorded a game event or left the game state different
-- (`happenedBetween`), and an ignored one did neither. A board difference, the
-- posture applyEffectWith's CR 607.2a filing already takes, so the rules core
-- never asks which effect it was; the two ruled shapes below read a
-- classification of its choice and a shortfall it recorded. Ratchet, Field
-- Medic's two trigger instances are Parun.TransformSpec's "CR 701.28e / 603.12
-- an ignored convert arms no reflexive", the event-log half; Strax, Sontaran Nurse's random choice records
-- no event and only binds a slot, and Parun.ResolveSpec's "CR 603.12 a choice
-- that records no event still arms its when you do" is the state half.
--
-- The comparison runs only where the NEXT instruction arms a reflexive, so the
-- fold carries the previous instruction's before and after states rather than
-- a verdict, and a clause with no arm never compares.
--
-- Effect.ForEach's body (Parun.Engine.Resolve.Arms.Zones) runs its instructions through this SAME fold,
-- reset per member rather than carried across members. Nihiloor's "for each
-- opponent, tap up to one untapped creature you control. When you do, ..." is
-- the printed shape, but cannot observe it: a reflexive armed off a tap that
-- tapped nothing has no creature to measure its target by, so it has no legal
-- target either way. Synthetic Communal Toll
-- (data/cards/synthetic-communal-toll.json) can; Parun.ResolveSpec's "CR 608.2f /
-- 603.12 a reflexive armed inside a ForEach reads only that member's own
-- instruction" is the case that proves it.
--
-- Only the instruction IMMEDIATELY before the arm is asked about. A reflexive
-- naming an earlier one ("do A. do B. when you do A this way") is written as its
-- own clause, gated on what A bound: CR 603.12 asks only whether A's event
-- occurred, and "this way" is the objects A acted on. Fiery Encore's "discard a
-- card, then draw a card" is the case; its scenario "CR 603.12 whole card: Fiery
-- Encore cast from an otherwise empty hand discards nothing, still draws, and
-- creates no reflexive" proves the draw is not what it reads. The one widening
-- is a CR 608.2d choice written as its own opcode ahead of the act on it
-- (`choiceAhead`): "tap any number of untapped artifacts you control" is one
-- printed instruction, so the choice's classification rides with the tap.
--
-- Two rulings settle what happenedBetween's board difference cannot
-- (`instructionDone`). An "any number" choice is done whatever it picks,
-- since CR 107.1c makes zero a full answer: Yotia Declares War's
-- 2022-09-09 ruling, proved by the scenario "CR 603.12 Yotia Declares War
-- tapping zero artifacts still arms its reflexive". And a draw or a mill that
-- found too few cards (`GameState.fellShort`) is not done: The Royal Scions'
-- 2019-10-04 ruling, proved by "CR 603.12 The Royal Scions drawing two of four
-- arms no reflexive", and Wick's Patrol's for the mill, by "CR 603.12 Wick's
-- Patrol milling two of three arms no reflexive". Both are CR 603.12's alone:
-- CR 118.12's "If you do" asks whether a cost was started, whatever it came to
-- (Resolve.recordTaken).
applyClauseEffects ::
  ObjectId ->
  ObjectId ->
  (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()) ->
  [Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)] ->
  Game ()
applyClauseEffects resolving source applyOne =
  let step previous effect = do
        arms <- State.gets (armsReflexive resolving source effect)
        let skipped = arms && maybe False (not . instructionDone) previous
        before <- State.get
        Monad.unless skipped (applyOne effect)
        after <- State.get
        let ahead = maybe False (\asked -> aheadOfNext asked && admitsNone asked) previous
        pure (Just (MkAsked before after (ahead || choosesAnyNumber effect) (choiceAhead effect)))
   in Monad.foldM_ step Nothing

-- One instruction of applyClauseEffects' fold, as the next one asks about it:
-- the states it ran between, whether its choice -- or one written ahead of it
-- (`choiceAhead`) -- admitted choosing none, and whether it is itself such a
-- choice.
data Asked = MkAsked
  { askedBefore :: GameState,
    askedAfter :: GameState,
    admitsNone :: Bool,
    aheadOfNext :: Bool
  }

-- CR 603.12's "when you do", asked of the instruction before an arm.
instructionDone :: Asked -> Bool
instructionDone asked =
  admitsNone asked
    || ( happenedBetween (askedBefore asked) (askedAfter asked)
           && GameState.fellShort (askedAfter asked) == GameState.fellShort (askedBefore asked)
       )

-- CR 107.1c: does this instruction choose "any number", so that choosing none
-- is a full answer? A classification of the choice it makes, read off its
-- count. "Up to N" is not: Nihiloor's 2021-07-23 ruling puts a reflexive on
-- the stack "for each creature you tapped", and the scenario "CR 603.12 /
-- 608.2f Nihiloor tapping nothing for one opponent arms no reflexive for them"
-- holds it. The ObjectRef half goes through effectObjectRefs, the one
-- enumeration of where a ref sits; the opcodes carrying a count of their own
-- are named. Only ChoosePermanents is observed (Yotia Declares War); the other
-- arms are a REGRESSION FENCE, since no card in data/cards/ puts them ahead of
-- a mandatory "when you do".
choosesAnyNumber :: Effect card ability -> Bool
choosesAnyNumber effect =
  any refChoosesAnyNumber (effectObjectRefs effect) || case effect of
    Effect.ChoosePermanents choice -> anyNumber (ChosenPermanents.count (ChoosePermanents.permanents choice))
    Effect.Discard (Discard.AnyNumber discard) -> Maybe.isNothing (AnyNumberMatching.atMost (AnyNumberDiscard.cards discard))
    Effect.RemoveCountersAmong removal -> case RemoveCountersAmong.count removal of
      RemovalCount.Exactly {} -> False
      RemovalCount.UpTo {} -> False
      RemovalCount.AnyNumber -> True
    _ -> False
  where
    anyNumber howMany = howMany == HowMany.UpTo Nothing
    refChoosesAnyNumber ref = case ref of
      ObjectRef.ChosenPermanents chosen -> anyNumber (ChosenPermanents.count chosen)
      ObjectRef.ChosenCardFromAmong chosen -> anyNumber (ChosenCardFromAmong.count chosen)
      ObjectRef.AllOf refs -> any refChoosesAnyNumber refs
      _ -> False

-- CR 608.2d: a choice bound for the NEXT instruction to act on, which is how
-- parun writes the choosing half of one printed instruction.
choiceAhead :: Effect card ability -> Bool
choiceAhead effect = case effect of
  Effect.ChoosePermanents {} -> True
  Effect.Divide {} -> True
  _ -> False

-- CR 603.12: record that an instruction did fewer than the number it named.
fallShort :: Game ()
fallShort = State.modify' (\gs -> gs {GameState.fellShort = GameState.fellShort gs + 1})

-- CR 603.12: did the instruction that took the game from `before` to `after`
-- HAPPEN? Also CR 118.12's "started to pay a mandatory cost", for
-- Resolve.recordTaken's "If you do". Yes when it recorded a game event, or when anything but bookkeeping
-- changed. A field is bookkeeping, and copied across from `before` here, iff an
-- instruction that did NOT happen can still write it: the event log and its
-- CR 603.10 samples (read by the first disjunct, and the samples are
-- deliberately unforced), the allocators, interning and Oracle-reference memos
-- an instruction advances before finding nothing to do, CR 104.4b's lastChoice
-- (an offer answered with nothing), CR 121.4's drewFromEmpty (an attempted
-- draw) and fellShort (an instruction finding too few cards, which only
-- applyClauseEffects reads), CR 607.2a's exiledWith and CR 406.4's exilePiles (applyEffectWith
-- prunes both after EVERY instruction, and a card can leave exile off that
-- road -- CR 704.5d ceasing a token -- so the prune of a stale key is no act;
-- a real exile already shows in `exile` and `objects`), and every bound
-- AMOUNT and vote tally, since a tally binds zero for an instruction that did nothing -- a
-- slot that holds nothing else is dropped, so a FIRST zero bind is not a
-- difference either. Everything else is compared, so a new GameState field
-- counts as state by default.
--
-- A deny-list and not an allow-list: an allow-list fails as the event-log
-- reading did, on every state-only instruction writing a field it does not
-- name, which grows with the open half; this one fails only on a closed-half write made whether
-- or not anything happened, a finite set. docs/decisions.md,
-- "What counts as an instruction having happened".
--
-- docs/decisions.md's Site line names the tests proving the exiledWith,
-- exilePiles, nextTimestamp and nextEventGroup copies. The rest is a
-- REGRESSION FENCE rather than a proved line: un-copying lastChoice leaves the
-- suite green.
happenedBetween :: GameState -> GameState -> Bool
happenedBetween before after =
  let tallyless :: Map.Map SlotName Binding.Type.Binding -> Map.Map SlotName Binding.Type.Binding
      tallyless = Map.filter (/= Binding.Type.empty) . Map.map (\binding -> binding {Binding.Type.amount = Nothing, Binding.Type.votes = Nothing})
      objectTallyless :: Map.Map ObjectId Object.Object -> Map.Map ObjectId Object.Object
      objectTallyless = Map.map (\obj -> obj {Object.bindings = tallyless (Object.bindings obj)})
      comparable gs =
        gs
          { GameState.events = Seq.empty,
            GameState.boardAfterEvent = Map.empty,
            GameState.battlefieldWhenTriggered = Map.empty,
            GameState.nextEventGroup = GameState.nextEventGroup before,
            GameState.eventGroupDepth = GameState.eventGroupDepth before,
            GameState.nextTimestamp = GameState.nextTimestamp before,
            GameState.nextObjectId = GameState.nextObjectId before,
            GameState.nextPrintingId = GameState.nextPrintingId before,
            GameState.printings = GameState.printings before,
            GameState.printingIds = GameState.printingIds before,
            GameState.lookedUp = GameState.lookedUp before,
            GameState.referenceNames = GameState.referenceNames before,
            GameState.lastChoice = GameState.lastChoice before,
            GameState.drewFromEmpty = GameState.drewFromEmpty before,
            GameState.fellShort = GameState.fellShort before,
            GameState.exiledWith = GameState.exiledWith before,
            GameState.exilePiles = GameState.exilePiles before,
            GameState.ambientAmounts = GameState.ambientAmounts before,
            GameState.objects = objectTallyless (GameState.objects gs),
            GameState.stackArchive = objectTallyless (GameState.stackArchive gs),
            GameState.detachedBindings = Map.filter (not . Map.null) (fmap tallyless (GameState.detachedBindings gs))
          }
   in Seq.length (GameState.events after) > Seq.length (GameState.events before)
        || comparable before /= comparable after

-- CR 603.12: does this instruction create a REFLEXIVE triggered ability? The arm
-- is resolved exactly as the arm itself resolves it (Projection.armedDelayedAbility,
-- then rule 702's minted roster), and the answer is the created ability's own
-- CLASSIFICATION -- its trigger condition -- never which card armed it.
armsReflexive :: ObjectId -> ObjectId -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> GameState -> Bool
armsReflexive resolving source effect gs = case effect of
  Effect.ArmDelayedTrigger arm ->
    maybe
      False
      ((== TriggerCondition.Reflexive) . TriggeredAbility.condition)
      (Projection.armedDelayedAbility resolving source arm gs <|> Keyword.mintedDelayedAbility (ArmDelayedTrigger.name arm))
  _ -> False

-- The players a PlayerRef names, in CR 101.4's APNAP order -- playerRefPlayers
-- answers in PlayerId order and says so, leaving the ordering rule to its
-- caller. Its callers all ask for the same reason -- the seats a resolution cost
-- is offered to (CR 118.12a), the seats a printed "may" is offered to (CR
-- 603.5), the seats a CR 608.2d either-or is announced by, the seats CR 111.2
-- has creating tokens, the seats CR 201.4 has naming a card. Mana Leak's
-- reference names one and Rishadan
-- Cutpurse's names every opponent; the order is observable only where the
-- reference names more than one seat, which no printing in the pool does at the
-- naming caller (Petra Sphinx's is a target slot).
apnapPlayersOf :: PlayerRef -> Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> [PlayerId]
apnapPlayersOf ref legal resolving source controller gs =
  let named = playerRefPlayers legal resolving source controller gs ref
   in filter (\pid -> List.elem pid named) (Game.apnapOrder gs)

-- The players a PlayerRef names as DECIDERS -- a payer (CR 118.12), a "may"
-- asker (CR 603.5), an either-or chooser (CR 608.2d), a chooser (askedChooser)
-- -- read WITHOUT Players.resolution's CR 801.10 cut, which is for players the
-- effect affects. A departed decider stays named, so CR 800.4f and 800.4g can
-- answer for them. In PlayerId order.
decidersOf :: Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> PlayerRef -> [PlayerId]
decidersOf legal resolving source controller gs ref =
  Maybe.fromMaybe [] (Players.named (resolutionReads legal resolving source controller gs) {Players.reaches = const True} gs ref)

-- decidersOf in CR 101.4's APNAP order, apnapPlayersOf's ordering. Proved by
-- Parun.RangeOfInfluenceSpec's "CR 801.10 a payer outside the controller's
-- range is still offered the payment" (Cut the Tethers).
apnapDecidersOf :: PlayerRef -> Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> [PlayerId]
apnapDecidersOf ref legal resolving source controller gs =
  let named = decidersOf legal resolving source controller gs ref
   in filter (\pid -> List.elem pid named) (Game.apnapOrder gs)

-- The ONE seat a PlayerRef names, for a designation CR 725.3 and CR 726.3 give
-- to exactly one player at a time; a reference naming nobody or several moves
-- nothing (CR 101.3).
oneSeat :: Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> PlayerRef -> Maybe PlayerId
oneSeat legal resolving source controller gs ref = case playerRefPlayers legal resolving source controller gs ref of
  [pid] -> Just pid
  _ -> Nothing

-- CR 608.2c / 800.4g: the ONE seat a choice opcode's own chooser reference
-- names, and who answers instead when that seat has LEFT the game.
--
-- A RELATION ("an opponent chooses") is a seat the controller names, as
-- Parun.Engine.Target.chooserOf names "an opponent's choice": out of
-- Players.chooserOffer, so CR 801.5c hands the choice to the nearest seat in the
-- relation to the controller's left where none is in range.
--
-- Any other reference naming nobody, or naming several where no printing writes
-- one, answers Nothing: that share of the instruction is ignored (CR 101.3).
--
-- The REASSIGNMENT is rule 800.4g's, and it is a choice rather than a fallback
-- to the controller: the object's controller picks the substitute, narrowed to
-- another opponent where the departed chooser was one of theirs (CR 801.5c's
-- nearest one where none is in range) and widened back to the whole table where
-- no opponent is left. "Another" needs no exclusion of its own,
-- Game.stillPlaying having already dropped the seat that left. The departure
-- scenario "CR 801.5c a departed opponent's choice goes to the nearest opponent
-- out of range" proves the range half.
--
-- The ask is Parun.Engine.Players.chooseOne, every "choose a player" site's.
-- The chooser reference is read through decidersOf, so a departed chooser is
-- still named here and replaced.
--
-- CR 800.4f is the same situation for a COST and the opposite answer -- the cost
-- is not paid, and nobody is asked in the departed player's place -- which is
-- why it lives in payGatePaidBy and not here.
--
-- Parun.DepartureSpec's "CR 800.4g a departed player's choice is made by another
-- opponent" is what proves the reassignment.
--
-- The two PLURAL askers are not routed here at all, whatever a card writes into
-- them: Parun.Types.Optionality's asker (CR 603.5, Resolve.exercises) and
-- Parun.Types.OrElse's chooser (CR 608.2d, Resolve.chosenBranch and
-- villainousPass) both go through apnapPlayersOf above, which answers a SET off
-- Game.stillPlaying and so has already dropped a departed seat rather than
-- reassigning its answer.

-- CR 608.2d's choice in a shared zone, hoisted so that every opcode making one
-- asks it the same way: the candidates are the ability's own reading of the
-- Filter whoever chooses (CR 109.5), chosenCandidates' sweep read live off the
-- board before the instruction acts (CR 608.2c), and the chooser is reached
-- through askedChooser, CR 800.4g included. The chooser is named only where the
-- count leaves a real choice, so CR 800.4g's reassignment is never asked for a
-- choice with one answer.
--
-- The count is pickCounted's, read here -- Teferi, Hero of Dominaria's "up to
-- two lands".
chosenPermanents :: AnyNumberOf.AnyNumberOf -> Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> ChosenPermanents.ChosenPermanents -> Game [ObjectId]
chosenPermanents purpose legal resolving controller source choice = do
  gs <- State.get
  let candidates = chosenCandidates legal resolving controller source gs choice
      chooser = ChosenPermanents.chooser choice
      count = ChosenPermanents.count choice
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      amount = maybe 0 Integer.toNaturalSaturating . Quantity.evaluateFor (effectViewOf resolving source legal gs) context gs resolving source
  pickByChooser
    resolving
    source
    controller
    legal
    chooser
    (\decider who -> Prompt.ChoosePermanent decider who source)
    (\decider who pool ceiling_ -> Prompt.ChooseAnyNumber decider who source purpose pool ceiling_)
    amount
    count
    candidates

-- Game.pickCounted with the seat a chooser ref names, for chosenPermanents and
-- chooseCardFromAmong. CR 801.5a under a limited range: the chooser names only
-- what is in their own range, so the seat is settled FIRST and a permanent is
-- offered only where its controller is within the chooser's range (CR 801.2d).
-- A card nobody controls stays offered, CR 801.5c's own Fact or Fiction
-- example. Under an unlimited range the seat is asked only where a real choice
-- remains. Parun.RangeOfInfluenceSpec's "CR 801.5a a chooser handed the choice
-- names only permanents in their own range" proves the cut.
pickByChooser ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  PlayerRef ->
  (Decider.Decider -> PlayerId -> NonEmpty.NonEmpty ObjectId -> Prompt.Prompt ObjectId) ->
  (Decider.Decider -> PlayerId -> [ObjectId] -> Maybe Natural -> Prompt.Prompt (Set ObjectId)) ->
  (Quantity.Type.Quantity -> Natural) ->
  HowMany.HowMany ->
  [ObjectId] ->
  Game [ObjectId]
pickByChooser resolving source controller legal chooser one_ several amount count candidates = do
  gs <- State.get
  let named = namesChooser legal resolving source controller gs chooser
      asked = askedChooser resolving source controller legal chooser
  if Map.null (RangeOfInfluence.unwrap (GameSettings.rangeOfInfluence (GameState.settings gs)))
    then Game.pickCounted named asked one_ several amount count candidates
    else do
      seat <- if named then asked else pure Nothing
      now <- State.get
      let grants = Projection.controlGrants now
          reachable who oid = not (Set.member oid (GameState.battlefield now)) || Projection.objectInRangeGiven grants who oid now
      case seat of
        Nothing -> pure []
        Just who -> Game.pickCounted True (pure (Just who)) one_ several amount count (filter (reachable who) candidates)

-- Whether a chooser ref names a seat to ask, askedChooser's test without its ask.
namesChooser :: Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> PlayerRef -> Bool
namesChooser legal resolving source controller gs ref = case ref of
  PlayerRef.Relative relation -> not (List.null (Players.chooserOffer controller gs relation))
  _ -> length (decidersOf legal resolving source controller gs ref) == 1

askedChooser :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game (Maybe PlayerId)
askedChooser resolving source controller legal ref = do
  gs <- State.get
  case (ref, decidersOf legal resolving source controller gs ref) of
    (PlayerRef.Relative relation, _) -> Players.chooseOne controller source Nothing (Players.chooserOffer controller gs relation)
    (_, [named])
      | List.elem named (Game.stillPlaying gs) -> pure (Just named)
      | otherwise ->
          let -- CR 801.5a: a player the controller chooses is one in range.
              opponents = Players.chooserOffer controller gs PlayerRelation.Opponent
              candidates =
                if Game.areOpponents gs controller named && not (List.null opponents)
                  then opponents
                  else Players.offer controller gs PlayerRelation.AnyPlayer
           in Players.chooseOne controller source Nothing candidates
    _ -> pure Nothing

-- CR 701.3a for several movers going to one destination together. CR 613.7m:
-- they take CR 701.3c's stamps in APNAP order, each seat choosing its own, asked
-- before the fold that mints them, as turnPermanentsOver asks -- and only of the
-- movers the move will restamp, since Event.attach refuses the rest (CR 701.3b).
-- No board observes the order (gap #4214).
attachTogether :: [ObjectId] -> Recipient -> Game ()
attachTogether movers recipient = do
  gs <- State.get
  let restamped mover = case Attach.attachmentFor mover recipient gs of
        Just attachment -> fmap Object.attachedTo (Game.lookupObject mover gs) /= Just (Just attachment)
        Nothing -> False
  ordered <- Restamp.order (filter restamped movers)
  Foldable.for_ (ordered <> filter (not . restamped) movers) $ \mover ->
    Event.attach mover recipient

-- The objects an ObjectRef names, for every opcode whose ref may be a CR 608.2d
-- question: the asking arms are answered here in the Game monad, and every other
-- arm is objectRefObjects' pure sweep, read off the board as it stands (CR
-- 608.2c). The ONE asker, so no two opcodes can ask a ref differently; which
-- (opcode, arm) pairs a card may write is Parun.EffectLintSpec's inertChoosers.
--
-- Every ask reads its candidates off the board before the instruction acts and
-- filters the answer rather than trusting it.
askingObjects ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  Map.Map SlotName (Set Recipient) ->
  ObjectRef.ObjectRef ->
  Game [ObjectId]
askingObjects resolving source controller legal chosen ref = case ref of
  -- Fall of the Thran's "two land cards from their graveyard": the count per
  -- chooser, DISTINCT cards (CR 608.2d), asked in APNAP order (CR 101.4).
  ObjectRef.ChosenCardInGraveyard fromGraveyard -> chosenCardsInGraveyard legal resolving controller source fromGraveyard
  -- The arm above over CR 400.2's hidden zone, CR 402.3 deciding who may be
  -- asked.
  ObjectRef.ChosenCardInHand inHand -> chooseCardsInHand resolving source controller legal inHand
  -- The printed "from among them".
  ObjectRef.ChosenCardFromAmong from -> chooseCardFromAmong resolving source controller legal chosen from
  -- Randomness, asked of the interpreter.
  ObjectRef.RandomCardInHand random -> randomCardsInHand resolving source controller legal random
  ObjectRef.RandomCardInGraveyard random -> randomCardsInGraveyard resolving source controller legal random
  ObjectRef.RandomCardInLibrary random -> randomCardsInLibrary resolving source controller legal random
  -- Capricious Efreet's "one of them": the pool read or asked first, then one
  -- drawn from it. The pool's InSlot reads `legal`, so a target CR 608.2b made
  -- illegal is not among them.
  ObjectRef.AtRandom inner -> do
    pool <- askingObjects resolving source controller legal chosen inner
    Maybe.maybeToList <$> Game.drawAmong Prompt.RandomObject pool
  -- Tovolar's "any number of Human Werewolves you control", read off a board CR
  -- 702.145c has already turned him over on.
  ObjectRef.ChosenPermanents choice -> chosenPermanents AnyNumberOf.Permanents legal resolving controller source choice
  -- Each ref asked or read in the order written, before anything moves; an
  -- object two refs name is named once.
  ObjectRef.AllOf refs -> fmap (ListUtils.nubOrd . concat) (traverse (askingObjects resolving source controller legal chosen) (NonEmpty.toList refs))
  -- Every other arm is a read. Exhaustive with no `_`, so a new arm has to say
  -- which it is: one answered [] by objectRefObjects but falling through here
  -- would name nothing.
  ObjectRef.InSlot _ -> swept
  ObjectRef.EachMatching _ -> swept
  ObjectRef.EachCardInGraveyard _ -> swept
  ObjectRef.EachCardInYourHand -> swept
  ObjectRef.EachCardInHand _ -> swept
  ObjectRef.EachCardInYourLibrary _ -> swept
  ObjectRef.EachCardYouOwn _ -> swept
  ObjectRef.EachCardInExiledPile _ -> swept
  ObjectRef.EachCardEncodedOnSource _ -> swept
  ObjectRef.EachSpell _ -> swept
  ObjectRef.EachAbility _ -> swept
  ObjectRef.EachOnStack _ -> swept
  ObjectRef.EachPlayer -> swept
  ObjectRef.EachOpponent -> swept
  ObjectRef.ChosenPlayer -> swept
  ObjectRef.Players _ -> swept
  ObjectRef.TopOfLibrary _ -> swept
  ObjectRef.TopOfLibraryUntil _ -> swept
  ObjectRef.TopOfGraveyard _ -> swept
  ObjectRef.EachCardFromAmong _ -> swept
  ObjectRef.AttachedToBound _ -> swept
  ObjectRef.FromAnywhere _ -> swept
  where
    swept :: Game [ObjectId]
    swept = State.gets (\gs -> objectRefObjects legal resolving controller source gs ref)

-- CR 608.2f: the members Effect.ForEach runs its body over, swept once. A card
-- the controller chooses from among revealed ones is asked here (Shimian
-- Specter's "You choose a nonland card from it", proved by the scenario
-- shimian-specter-exiles-every-card-named-like-the-one-it-picks); every other
-- ref is objectRefRecipients' read, and Parun.EffectLintSpec's inertChoosers
-- keeps a card from writing any other chooser here.
loopMembers :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef.ObjectRef -> Game [Recipient]
loopMembers resolving source controller legal chosen ref = case ref of
  ObjectRef.ChosenCardFromAmong _ -> fmap Recipient.ToObject <$> askingObjects resolving source controller legal chosen ref
  _ -> State.gets (\gs -> objectRefRecipients legal resolving controller source gs ref)

-- CR 701.9a's move for every Effect.Discard arm, once the cards are named:
-- each seat's cards through the shared discard funnel, so the discard is
-- recorded for a trigger to read. The funnel's own answers come back for the
-- binding below; a move that did not complete answers Nothing and is dropped.
-- One event group across the seats, CR 101.4's "simultaneously", whose close
-- asks CR 401.4's arrangement of what a redirect put into a library and CR
-- 404.3's of what reached a graveyard. The cause
-- is Event.resolvingDiscardCause's: a CR 118.12 cost is no effect.
buryDiscards :: ObjectId -> Maybe SlotName -> [(PlayerId, [ObjectId])] -> Game ()
buryDiscards resolving mDiscarded doomed = do
  cause <- State.gets Event.resolvingDiscardCause
  moved <-
    Event.simultaneously . fmap concat . Monad.forM doomed $ \(victim, oids) ->
      fmap (concatMap Foldable.toList) (Monad.mapM (Event.discardReturning cause victim) oids)
  -- The cards "discarded this way", for a later effect of the same resolution
  -- to look back at -- Psychic Miasma's "if a land card is discarded this way".
  -- The CR 400.7 incarnations the funnel MINTED, never the hand ids it was
  -- handed: the hand incarnation no longer exists, so a reader of the
  -- destination zone could match none of them. Destroy's `buried` slot binds
  -- on exactly that argument.
  --
  -- The UNION across seats, since the slot is already a GROUP binding and a
  -- multi-seat discard is one event batch (CR 608.2f); at one seat that is the
  -- singleton it always was, so Psychic Miasma is unchanged.
  --
  -- No board filter of `buried`'s kind: CR 701.9c takes a card put somewhere
  -- other than its owner's graveyard to have been discarded all the same, so
  -- what the funnel moved is what was discarded wherever it landed. CR 400.7j
  -- then decides whether a later part of the effect can FIND it -- a public
  -- destination yes, a hidden one only if the card was revealed on the way
  -- (CR 701.9c) -- which is a question about the reader.
  --
  -- Bound onto `resolving` and as a GROUP, `buried`'s shape and for its reason:
  -- slotBindings reads live GameState unconditionally, which is what puts the
  -- slot in front of Filter.IsBound when the NEXT clause's gate is evaluated. A
  -- single binding would land in the target half of the context instead, where
  -- gateHolds does not look. Nothing is bound when nothing moved, so the gate
  -- finds an unbound slot and the "if" is false -- which is what the rider asks
  -- for.
  Monad.forM_ mDiscarded $ \bound ->
    Monad.unless (null moved) (State.modify' (bindObjectsSlot resolving bound (Seq.fromList moved)))

-- CR 701.27a and CR 701.28a: turn each named permanent over. ONE function for
-- both opcodes, which is CR 701.28a said as code -- "this follows rules
-- 701.27a-f, 712.9-10, and 712.18", so a convert cannot pick up a gate a
-- transform lacks, nor miss one it has.
turnPermanentsOver ::
  Map.Map SlotName (Set Recipient) ->
  Map.Map SlotName (Set Recipient) ->
  ObjectId ->
  PlayerId ->
  ObjectId ->
  ObjectRef.ObjectRef ->
  Game ()
turnPermanentsOver legal chosen resolving controller source ref = do
  -- WHICH permanents turn over, gathered BEFORE the turn (CR 608.2f).
  victims <- askingObjects resolving source controller legal chosen ref
  -- CR 613.7m: which of the swept victims will ACTUALLY take a stamp, ordered by
  -- their controllers. Asked BEFORE the write and off the pre-turn board, the
  -- gather's own reason (CR 608.2f), and `turnsOver` below is the whole
  -- membership question, so a permanent this instruction cannot turn over is no
  -- part of anybody's choice.
  gs0 <- State.get
  ordered <- Restamp.orderTurning (filter (turnsOver (Projection.projectAll gs0) resolving gs0) victims)
  State.modify' $ \gs ->
    -- CR 701.27a: turn each victim over -- one assignment to Object.face, which
    -- is all a turn IS here, every characteristic read already resolving
    -- through Game.faceOf. The victims were enumerated ONCE above (CR 608.2f),
    -- ahead of this write so no member of the batch is judged against a board a
    -- sibling has already turned over on. WHICH face is
    -- Parun.Engine.Card.turnedOver's answer, off the card's layout, which
    -- withholds a turn from a permanent that is not double-faced (CR 701.27c)
    -- or whose other face is an instant or sorcery (CR 701.27d).
    --
    -- CR 701.27b: turning over is its own game action, so it records its own
    -- event -- Event.recordTransformed, over the victims that ACTUALLY turned
    -- rather than the ones this instruction named, since the ways a turn
    -- is withheld leave nothing for CR 603.2 to fire on.
    --
    -- AFTER the fold, and the order is load-bearing: Parun.Engine.Card gives a
    -- transforming permanent only the SHOWN face's abilities, so a trigger
    -- printed on the face just turned to is among recordEvent's candidates only
    -- because the write has already happened. Parun.TransformSpec's CR 701.27e
    -- group is what proves it.
    --
    -- ONE fresh timestamp for the whole instruction (CR 701.27f), minted even
    -- when nothing turns over, and ONE whole-board projection, CR 702.145b's
    -- restriction being read off the layer fold. CR 613.7g's per-permanent stamp
    -- is a second thing, minted inside Game.turnFaceOver.
    --
    -- LEFT fold, where this was a right one before the stamp: the fold hands out
    -- CR 613.7g's timestamps, so it must run `ordered` forwards for the earlier
    -- stamp to go to the permanent CR 613.7m put first.
    let (now, g1) = Game.freshTimestamp gs
        g2 = List.foldl' (flip (Game.turnFaceOver now)) g1 ordered
     in Event.recordTransformed
          (Game.facesTurned (GameState.objects g1) (GameState.objects g2) ordered)
          g2

-- CR 701.27a over ONE object, asked rather than performed: whether this
-- instruction turns it over. The act itself is Game.turnFaceOver, shared with
-- Parun.Engine.Daytime's CR 702.145c/f sweep, and Game.turnsTo is the act's own
-- half of this question. What this adds is the two gates that belong to an
-- INSTRUCTION rather than to the act, and a static ability's turn has neither: CR
-- 701.27f's already-turned check, and CR 702.145b/e's "can't transform except due
-- to its daybound/nightbound ability" (Parun.Engine.Daytime.restrictsTransform).
--
-- Asked of the PRE-TURN board (CR 608.2f's simultaneous processing), so no member
-- of the batch is judged against a board a sibling has already turned over on,
-- and `pcs` is that board's projection.
turnsOver :: Map.Map ObjectId PC.ProjectedCharacteristics -> ObjectId -> GameState -> ObjectId -> Bool
turnsOver pcs resolving frozen oid =
  not (alreadyTurnedFor resolving oid frozen)
    && not (Daytime.restrictsTransform pcs oid)
    && Maybe.isJust (Game.turnsTo oid frozen)

-- CR 701.27f. True when this resolution must be ignored: the resolving object is
-- an ability whose SOURCE is the very permanent being turned over (CR 113.7a),
-- and that permanent's last turn is later than the moment the rule measures that
-- ability from.
--
-- WHICH moment is the rule's two sentences, and they differ observably. An
-- ordinary ability is measured from when it was put onto the stack, which is its
-- own CR 613.7d timestamp. A DELAYED triggered ability is measured from when it
-- was CREATED, which is earlier and can sit on the far side of a turn-over its
-- placement stamp is on the near side of -- Parun.TransformSpec's Aang pair is
-- the board that tells the two apart. Every stamp comes from
-- GameState.nextTimestamp, so one `>` decides it and equality cannot arise.
alreadyTurnedFor :: ObjectId -> ObjectId -> GameState -> Bool
alreadyTurnedFor resolving victim gs =
  -- Both of the rule's narrowings at once, and a CLASSIFICATION of the
  -- resolving object throughout, never which card it is: Nothing unless the
  -- object is an ability OF the victim, and otherwise the moment to measure
  -- from. CR 725.2's sourceless inherent trigger has no permanent to be an
  -- ability of, so it falls out with the spells.
  let startedAt ability = case Object.source ability of
        Source.OfAbility activated
          | ActivatedAbilitySource.source activated == victim -> Just (Object.timestamp ability)
          | otherwise -> Nothing
        Source.OfTrigger triggered
          | TriggeredAbilitySource.source triggered == victim ->
              -- CR 603.7a's creation moment when there is one, and the placement
              -- stamp otherwise: an ability the source itself has carries none.
              Just (Maybe.fromMaybe (Object.timestamp ability) (TriggeredAbilitySource.createdAt triggered))
          | otherwise -> Nothing
        Source.OfCard _ -> Nothing
        Source.OfMeld _ -> Nothing
        Source.OfMerge _ -> Nothing
        Source.OfToken _ -> Nothing
        Source.OfEmblem _ -> Nothing
        Source.OfSpellCopy _ -> Nothing
        Source.OfCardCopy _ -> Nothing
        Source.OfInherentTrigger _ -> Nothing
   in case Game.lookupObject resolving gs of
        Nothing -> False
        Just ability -> case startedAt ability of
          Nothing -> False
          Just started -> maybe False (> started) (Game.lookupObject victim gs >>= Object.turnedOverAt)

-- The cards in the named graveyards matching the filter, for
-- ChosenCardInGraveyard's TheController chooser -- ObjectRef.EachCardInGraveyard
-- is this same fold, spelled out at its own arm. A card in a
-- graveyard has no controller, so Filter.HeldBy Holder.Controller is vacuously False. APNAP
-- (CR 101.4) then ascending ObjectId, not the graveyard's own pile order (CR
-- 404.2), which no rule makes a batch's processing order.
graveyardCards :: Filter.Context -> Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> GameState -> ZoneScope.ZoneScope -> Filter.Type.Filter Keyword.Type.Keyword -> [ObjectId]
graveyardCards context bindings source controller gs scope filter_ =
  concatMap (\pid -> graveyardCardsOf context gs pid filter_) (Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) bindings scope gs)

-- askingObjects' ChosenCardInGraveyard arm.
chosenCardsInGraveyard :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> ChosenCardInGraveyard.ChosenCardInGraveyard -> Game [ObjectId]
chosenCardsInGraveyard legal resolving controller source (ChosenCardInGraveyard.MkChosenCardInGraveyard chooser scope filter_ count) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      wanted = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source count)
      -- `made` is every card this pass has taken so far, beside
      -- who took it: CR 101.4b lets a later chooser know them.
      pick made asked n candidates
        | n <= (0 :: Natural) = pure made
        | otherwise = do
            picked <- Game.chooseAmong (\decider who pool -> Prompt.ChooseCardInGraveyard decider who source pool made) asked candidates
            case picked of
              Nothing -> pure made
              Just taken -> pick (made Seq.|> (asked, taken)) asked (n - 1) (List.delete taken candidates)
      ask asked = fmap (fmap snd . Foldable.toList) . pick Seq.empty asked wanted
  case chooser of
    Chooser.TheController -> ask controller (graveyardCards context legal source controller gs scope filter_)
    Chooser.EachInScope ->
      fmap (fmap snd . Foldable.toList) . Monad.foldM (\made pid -> pick made pid wanted (graveyardCardsOf context gs pid filter_)) Seq.empty $
        Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) legal scope gs
    -- ONE chooser, read out of the slot a ChoosePlayer bound,
    -- choosing out of their own graveyard. Through playerRefPlayers so
    -- the slot is read as every other is (CR 608.2b): an unfilled,
    -- illegal, non-player or many-valued slot names nobody, and nobody
    -- asked is nothing moved (CR 101.3). Intersected with the scope, so
    -- a chooser the scope does not name is offered nothing.
    Chooser.BoundInSlot slot ->
      case playerRefPlayers legal resolving source controller gs (PlayerRef.InSlot slot) of
        [pid] | List.elem pid (Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) legal scope gs) -> ask pid (graveyardCardsOf context gs pid filter_)
        _ -> pure []

-- The seats an ObjectRef.ChosenCardInHand asks -- and an
-- ObjectRef.RandomCardInHand reads -- in APNAP order. One list, not a chooser
-- plus a scope: CR 402.3 lets a player look only at their own hand. Through
-- playerRefPlayers, so an unfilled, illegal or non-player slot names nobody and
-- CR 101.3 ignores that share (CR 608.2b).
handChoosers :: Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectId -> PlayerId -> GameState -> PlayerRef -> [PlayerId]
handChoosers legal resolving source controller gs player =
  let named = playerRefPlayers legal resolving source controller gs player
   in filter (`elem` named) (Game.apnapOrder gs)

-- CR 401.2 and CR 401.4: turn the effect's LibraryPlacement into the END each
-- moving object arrives at, and hand back the batch in the order the moves must
-- then be PERFORMED in. Both questions are asked before anything moves (CR
-- 608.2f): CR 401.2 once per object, asked of the OWNER in the sweep's APNAP
-- order (CR 101.4); CR 401.4 once per (owner, end) group of two or more, whose
-- decider is the owner rather than CR 608.2f's resolving controller -- except
-- where the effect states a RANDOM order, which takes that arrangement back from
-- the owner and randomises the group instead (CR 701.24a's standard), or names
-- who orders it (LibraryPlacement.ArrangedBy, asked through `chooserOf`).
--
-- The arrangement answer names the cards from the chosen end INWARD, and
-- Game.insertIntoZone puts every arrival AT that end, so the batch is performed
-- in REVERSE of the arranged order -- one rule for both ends. A move the CR
-- 616.1 loop cancels (CR 614.6) simply does not arrive, and the rest keep their
-- owner's relative order.
--
-- Each arrival comes back with the number of cards to leave ABOVE it, nonzero
-- only at the top: LibraryPlacement.Beneath's depth, read through `depthOf`
-- once for the whole batch (CR 608.2h). moveOne arrives it on top and sinks it
-- that far, so a depth group arranged from the top inward lands in that order.
settleArrivals :: (PlayerRef -> Game (Maybe PlayerId)) -> (Quantity.Type.Quantity -> Natural) -> Zone.Zone -> LibraryPlacement.LibraryPlacement -> [ObjectId] -> Game [(ObjectId, (LibraryPosition.LibraryPosition, Natural))]
settleArrivals chooserOf depthOf zone placement targets =
  let upperOrBottom above owner oid gs = do
        position <- Game.choose (Prompt.ChooseLibraryEnd (Decide.deciderFor owner gs) owner oid above)
        pure $ case position of
          LibraryPosition.Top -> (LibraryPosition.Top, above)
          LibraryPosition.Bottom -> (LibraryPosition.Bottom, 0)
      settleEnd oid = do
        gs <- State.get
        case fmap Object.owner (Game.lookupObject oid gs) of
          -- Already gone (CR 603.7c). moveOne is a no-op, so nobody to ask.
          Nothing -> pure ((Nothing, (LibraryPosition.defaultValue, 0)), oid)
          Just owner -> do
            spot <- case placement of
              LibraryPlacement.Stated stated -> pure (stated, 0)
              LibraryPlacement.RandomOrder stated -> pure (stated, 0)
              LibraryPlacement.ArrangedBy arrival -> pure (ArrangedArrival.position arrival, 0)
              LibraryPlacement.OwnerChooses -> upperOrBottom 0 owner oid gs
              LibraryPlacement.Beneath quantity -> pure (LibraryPosition.Top, depthOf quantity)
              LibraryPlacement.BeneathOrBottom quantity -> upperOrBottom (depthOf quantity) owner oid gs
            pure ((Just owner, spot), oid)
      arrange settled key = do
        let batch = fmap snd (filter (\(k, _) -> k == key) settled)
            (mOwner, spot) = key
            position = fst spot
        case (mOwner, batch) of
          (Just owner, _ : _ : _) -> do
            ordered <- case placement of
              -- The effect states the order, so CR 401.4's owner is not asked.
              -- Prompt.Shuffle is the randomness channel the mulligan and CR
              -- 701.24a's own shuffle already go through, so the engine still
              -- rolls nothing; Game.honourShuffle refuses an answer that is not a
              -- permutation of the batch, which is what keeps a random order from
              -- inventing or destroying cards.
              LibraryPlacement.RandomOrder _ -> do
                answer <- Game.ask (Prompt.Shuffle batch)
                pure (Game.honourShuffle batch answer)
              _ -> do
                -- CR 608.2c / 608.2d: text naming who orders the batch hands
                -- CR 401.4's question to that player; a chooser naming nobody
                -- leaves it the owner's.
                named <- case placement of
                  LibraryPlacement.ArrangedBy arrival -> chooserOf (ArrangedArrival.chooser arrival)
                  _ -> pure Nothing
                let arranger = Maybe.fromMaybe owner named
                gs <- State.get
                answer <- Game.choose (Prompt.ArrangeLibraryArrivals (Decide.deciderFor arranger gs) arranger position batch)
                pure (Game.permute batch answer)
            pure (fmap (\oid -> (oid, spot)) (reverse ordered))
          -- One card is one order, which is CR 401.4's own "two or more".
          _ -> pure (fmap (\oid -> (oid, spot)) batch)
   in case zone of
        Zone.Library -> do
          settled <- Monad.mapM settleEnd targets
          fmap concat (Monad.mapM (arrange settled) (ListUtils.nubOrd (fmap fst settled)))
        -- No other destination has ends, so nothing to settle and the funnel ignores
        -- the position it is handed.
        _ -> pure (fmap (\oid -> (oid, (LibraryPosition.defaultValue, 0))) targets)

-- The same sweep as objectRefObjects, one step earlier: what an ObjectRef names
-- as RECIPIENTS. It exists because CR 115.4's "any target" includes a player and
-- CR 120.1 lets damage go to one, so DealDamage's InSlot arm must name something
-- no ObjectId can.
objectRefRecipients :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> GameState -> ObjectRef -> [Recipient]
objectRefRecipients legal resolving controller source gs ref = case ref of
  ObjectRef.InSlot slot -> case slotGroup slot resolving gs of
    -- A group is objects; a player is something only a TARGET slot can hold.
    Just group -> fmap Recipient.ToObject (Foldable.toList group)
    Nothing -> legalMany slot legal
  ObjectRef.EachMatching _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardInGraveyard {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardInYourHand -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardInHand {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardInYourLibrary _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardYouOwn _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardInExiledPile _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachCardEncodedOnSource {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.TopOfLibrary {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.TopOfLibraryUntil {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.TopOfGraveyard _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachSpell _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachAbility _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  ObjectRef.EachOnStack _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  -- CR 120.3a: a player is a damage recipient. The printed nouns "each player"
  -- and "each opponent" (CR 102.1, 109.5), resolved as the PlayerRef they
  -- spell and in APNAP order (CR 608.2f), so CR 801.10's range and CR 102.1's
  -- departed seat are cut where every other reference cuts them.
  -- Parun.RangeOfInfluenceSpec's and Parun.DepartureSpec's Fanatic of Mogis
  -- prove both.
  ObjectRef.EachPlayer -> fmap Recipient.ToPlayer (apnapPlayersOf (PlayerRef.Relative PlayerRelation.AnyPlayer) legal resolving source controller gs)
  ObjectRef.EachOpponent -> fmap Recipient.ToPlayer (apnapPlayersOf (PlayerRef.Relative PlayerRelation.Opponent) legal resolving source controller gs)
  -- CR 120.3a, one seat wide: the player the SOURCE chose as it entered (CR
  -- 614.12a), the printed noun for PlayerRef.ChosenPlayerOfBound over the
  -- source's own slot (CR 113.7a) -- not `resolving`, which for a triggered
  -- ability is the ability object and never carries the choice. So CR 608.2h's
  -- last known information answers for a source that has left, and CR 801.10
  -- cuts a chosen player outside the controller's range: Parun.RangeOfInfluenceSpec's
  -- "CR 801.10 a chosen player outside the controller's range is dealt no
  -- damage" proves it.
  ObjectRef.ChosenPlayer -> fmap Recipient.ToPlayer (apnapPlayersOf (PlayerRef.ChosenPlayerOfBound Binding.triggerSource PlayerChoice.AsEnters) legal resolving source controller gs)
  -- CR 120.3a, at whatever width the reference has: the seats a PlayerRef names,
  -- which for Deflecting Palm's HolderOfBound is CR 108.4's controller of the
  -- object a slot holds, read through CR 608.2h's last known information. The
  -- player Filter narrows them as the sweep beside it is read, as the effect
  -- executes (CR 608.2c): Disorder's "each player who controls a white
  -- creature", proved by the scenario
  -- cr-608-2c-disorder-deals-damage-to-each-player-who-controls-a-white-creature.
  ObjectRef.Players (PlayersWho.MkPlayersWho playerRef who) ->
    let context = effectContext gs resolving controller source legal (slotBindings resolving gs)
        kept pid = all (\f -> Count.playerMatches (effectViewOf resolving source legal gs) context gs f pid) who
     in fmap Recipient.ToPlayer (filter kept (apnapPlayersOf playerRef legal resolving source controller gs))
  -- No recipients: the answer needs the chooser asked, which askingObjects does.
  ObjectRef.ChosenCardInGraveyard {} -> []
  ObjectRef.ChosenCardInHand {} -> []
  ObjectRef.ChosenCardFromAmong {} -> []
  -- A read rather than a question, so the sweep above answers it -- and objects
  -- only, a group never holding a player.
  ObjectRef.EachCardFromAmong {} -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  -- No recipients, for the same reason.
  ObjectRef.RandomCardInHand _ -> []
  ObjectRef.RandomCardInGraveyard _ -> []
  ObjectRef.RandomCardInLibrary _ -> []
  ObjectRef.AtRandom _ -> []
  ObjectRef.ChosenPermanents _ -> []
  -- A read, so the sweep answers it.
  ObjectRef.AttachedToBound _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  -- A read, so the sweep answers it.
  ObjectRef.FromAnywhere _ -> fmap Recipient.ToObject (objectRefObjects legal resolving controller source gs ref)
  -- Each ref's recipients in the order written, one named twice named once.
  ObjectRef.AllOf refs -> ListUtils.nubOrd (concatMap (objectRefRecipients legal resolving controller source gs) refs)

-- The order for a per-object batch -- CR 608.2f's, and CR 701.44d's, which say
-- the same thing about the PRIMARY key: APNAP first, reading a player recipient
-- as that seat and an object as its controller's. Imposed here rather
-- than in objectRefRecipients, whose InSlot arm answers in Recipient (set)
-- order; this loop is the first reader that takes recipients one at a time.
--
-- The second key is a CHOICE, and which player makes it is the caller's, via
-- `chooserFor`: it is handed the group's own seat and answers who is asked, or
-- Nothing for nobody. CR 608.2f's secondary sentence gives it to the RESOLVING
-- CONTROLLER (`const (Just controller)`); CR 701.44d gives it to the player who
-- controls the permanents themselves (`id`), which is the only difference
-- between the two rules' orderings and the reason this takes a function.
--
-- Each seat's group is handed to its chooser as a Prompt.OrderForEach. Asked
-- once per group, in APNAP order of the groups; a group of one is not asked.
-- Game.permute keeps the engine's order for a non-permutation answer.
--
-- The GROUPING is what CR 701.44d's repeat clause describes as well: the first
-- APNAP seat holding any of the permanents keeps being first while it holds one,
-- so a whole seat's instructions run before the next seat's rather than
-- interleaving.
--
-- A recipient the board no longer holds has no controller and sorts last, which
-- is reachable rather than defensive (CR 400.7); two such share that bucket.
--
-- The seats' order is CR 101.4's APNAP order unless `start` names the seat a
-- card says to start with (Thieves' Auction's "starting with you"), and then it
-- is turn order from that seat.
forEachOrder :: ObjectId -> Maybe PlayerId -> (Maybe PlayerId -> Maybe PlayerId) -> [Recipient] -> Game [Recipient]
forEachOrder resolving start chooserFor recipients = do
  gs <- State.get
  let order = maybe (Game.apnapOrder gs) (`Game.turnOrderFrom` gs) start
      last_ = length order
      seatOf = recipientSeat gs
      rank recipient = maybe last_ (\pid -> Maybe.fromMaybe last_ (List.elemIndex pid order)) (seatOf recipient)
      groups = List.groupBy (\a b -> rank a == rank b) (List.sortOn (\recipient -> (rank recipient, recipient)) recipients)
      pick group = case group of
        first_ : _ : _ | Just chooser <- chooserFor (seatOf first_) -> do
          answer <- Game.choose (Prompt.OrderForEach (Decide.deciderFor chooser gs) chooser resolving group)
          pure (Game.permute group answer)
        _ -> pure group
  fmap concat (traverse pick groups)

-- WHOSE a recipient is: a player recipient is that seat, an object's is its
-- controller (CR 110.2) -- and CR 608.2h's last known information for an object
-- the board no longer holds, which is reachable rather than defensive (CR
-- 400.7): Effect.ForEach walks the permanents a destruction already removed.
-- CR 701.44c asks for the same read by name, and reading it here is what keeps
-- this and exploreOne agreeing about whose a departed permanent is.
-- Nothing only where neither answer exists; each caller says what it does with
-- that.
recipientSeat :: GameState -> Recipient -> Maybe PlayerId
recipientSeat gs recipient = case recipient of
  Recipient.ToPlayer pid -> Just pid
  _ -> Recipient.objectOf recipient >>= \oid -> Projection.controllerWithLastKnown oid gs

-- CR 701.21a: which player one Effect.Sacrifice instructs, as a pairing rather
-- than a performance -- the whole sweep goes to Event.sacrificeAll as one CR
-- 608.2f batch, so this names each member's sacrificing player and performs
-- nothing. The rule's second sentence -- "a player can't sacrifice ... something
-- that's a permanent they don't control" -- is what makes the two arms observably
-- different rather than two spellings of one thing.
--
-- EffectController names this effect's controller and lets the funnel REFUSE,
-- which is the printed "sacrifice it": Ray of Command stealing a Thatcher Revolt
-- token before its delayed "sacrifice those tokens" turns on leaves the token on
-- the battlefield, and Parun.ResolveSpec's "CR 701.21a a stolen token is not
-- sacrificed by the player who was told to sacrifice it" is the proof.
--
-- PermanentController reads the controller off the permanent instead (CR 613.1b's
-- layer 2), which is the printed "[that permanent]'s controller sacrifices it" --
-- CR 701.54c's three-temptation tier, whose blocker its own controller
-- sacrifices. Rule 701.21a can never refuse this arm, by construction. Read off
-- the board the BATCH was swept from, which is the same board the funnel judges
-- its two refusals against (CR 608.2f). Nothing to pair for an object that is
-- gone or has no controller (CR 400.7), which is also how the funnel answers.
sacrificerFor :: Sacrificer.Sacrificer -> PlayerId -> GameState -> ObjectId -> Maybe (PlayerId, ObjectId)
sacrificerFor sacrificer controller gs oid = case sacrificer of
  Sacrificer.EffectController -> Just (controller, oid)
  Sacrificer.PermanentController -> fmap (\pid -> (pid, oid)) (Projection.controllerOf oid gs)

-- slotGroup's singular: the ONE object bound at a slot, read live off the
-- resolving object rather than out of `chosen`, which is a PROJECTION -- CR
-- 601.2c's targets under CR 700.2d's names, gated on CR 608.2b legality. A
-- binding an earlier effect DEFINED is not a target, and is read here under the
-- name the card prints: CR 700.2d keeps two instances of one repeated mode apart
-- by emptying that name around each (Resolve.withDefinedSlots) rather than by a
-- rename this reader would have to follow. See bindObjectsSlot's note, and CR
-- 603.7c for why the binding exists.
--
-- Nothing when the slot is unbound, holds a group, names several targets, or
-- names a player: both callers want one object or none.
slotOne :: SlotName -> ObjectId -> GameState -> Maybe ObjectId
slotOne slot resolving gs = do
  obj <- Game.lookupObject resolving gs
  Map.lookup slot (Binding.objectSlots (Object.bindings obj))

-- slotOne's PLAYER twin (CR 115.1), read the same way and with the same
-- collapse: a slot that is unbound, holds a group, or holds an object names
-- nobody. CR 702.116a's loop slot is the one reader.
slotOnePlayer :: SlotName -> ObjectId -> GameState -> Maybe PlayerId
slotOnePlayer slot resolving gs = do
  obj <- Game.lookupObject resolving gs
  Map.lookup slot (Binding.playerSlots (Object.bindings obj))

-- The ONE player a slot names, from CR 608.2b's surviving recipients first and
-- from the resolving object's own bindings otherwise. Two sources for
-- fromAmongMembers' reason one recipient kind over: CR 608.2f's loop binds this
-- iteration's member into the handed-down maps and never onto the object, and a
-- slot an earlier effect defined is only on the object. Nothing where the slot
-- names none or several.
onePlayerNamed :: Map.Map SlotName (Set Recipient) -> SlotName -> ObjectId -> GameState -> Maybe PlayerId
onePlayerNamed legal slot resolving gs = case Maybe.mapMaybe Recipient.playerOf (legalMany slot legal) of
  [pid] -> Just pid
  _ -> slotOnePlayer slot resolving gs

-- CR 508.4: what an entry rider says the arriving creature attacks. Nothing: it
-- does not enter attacking. Combat.Any: its controller chooses, which
-- Combat.putOntoBattlefieldAttacking asks. Combat.Specified: the effect
-- specified it (CR 702.49c), read through CR 608.2h for a slot whose object has
-- left (ninjutsu's returned creature, CR 400.7). A slot naming no creature that
-- was attacking specifies nothing to attack, so nothing enters attacking.
--
-- Combat.Under is CR 702.116a's narrowing: the slot names a PLAYER rather than an
-- object, and a slot naming none narrows to nobody, so nothing enters attacking
-- -- the myriad iteration whose opponent has left the game (CR 800.4a).
entryAttack :: Map.Map SlotName (Set Recipient) -> ObjectId -> EntryRiders.EntryRiders count ability -> GameState -> Maybe Combat.AttackChoice
entryAttack legal resolving entry gs = case EntryRiders.attacking entry of
  Nothing -> Nothing
  Just EntryAttack.Chosen -> Just Combat.Any
  Just (EntryAttack.SameAs slot) -> do
    named <- slotOne slot resolving gs
    fmap Combat.Specified (Game.attackTargetWithLastKnown named gs)
  Just (EntryAttack.UnderPlayer slot) -> fmap Combat.Under (onePlayerNamed legal slot resolving gs)

-- CR 707.12: "the copy is created in the same zone the object is in and then
-- cast". The copy this mints is what `offerCast` above offers in the original's
-- place, so the original stays where it lies -- Mizzix's Mastery's exiled card
-- is still in exile once the copy has been cast, which is what
-- Parun.CopySpec's Mizzix's Mastery case proves.
--
-- Source.OfCardCopy and not OfCard, which is CR 704.5e's whole distinction: this
-- copy ceases to exist anywhere but the stack and the battlefield, where the card
-- it copies does not. CR 722.3c's prepare copy is the other minter of that source
-- and the road the cast itself already travels.
--
-- The SAME PRINTING as the original rather than an interned one of its own
-- (Parun.Engine.Prepare.mint's road), because nothing is narrowed here: CR 707.12
-- copies the object whole, so the copy's card is the copied card. Its copiable
-- values ride along the same way -- an original carrying a CR 707.2 snapshot
-- hands that snapshot on (a copy of a copy has the copied values, not the
-- printed ones), and an original carrying none leaves the copy reading its
-- printing, which is what Parun.Engine.Projection.View.copiableCharacteristics
-- answers for both. That first limb is a REGRESSION FENCE rather than a proved
-- line: the one stamped original a producer in data/cards/ reaches is paradigm's
-- archived spell below, whose stamp is its own printed values.
--
-- Object.newIncarnation for everything else, CR 400.7's forgetting: the copy is
-- a new object, so no counter, designation or announced cost of the original's
-- rides onto it, and a field added to Object is reset here by construction.
--
-- Its OWNER is the caster, which CR 112.2a states outright -- "the owner of that
-- copy is the player who is instructed to create it and given permission to cast
-- it" -- and which has to be settled here rather than at the cast: parun indexes
-- a zone by seat, so the copy is put into the caster's share of the zone it was
-- made in and CR 704.5e's sweep can find it there again.
--
-- No zone-change event, Parun.Engine.Prepare.mint's reason: the copy is CREATED
-- in that zone rather than moved there, so nothing was exiled or discarded and
-- no zone-change trigger has an event to watch.
--
-- A SPELL that has left the stack is copied from GameState.stackArchive (CR
-- 608.2h), and its copy is created in exile: an object in no zone has no "same
-- zone", and rule 702.192a's "create a copy of this object in exile" is the one
-- producer whose reference outlives its spell (Keyword.paradigmCopy).
--
-- Any other object that has left is copied from its last known information (CR
-- 608.2h), in the zone it left: God-Eternal Kefnet's ruling (2019-05-03), "if
-- the card leaves your hand before Kefnet's triggered ability resolves, you'll
-- copy it using its last known information", the copy "created in and cast from
-- your hand". The scenario "CR 608.2h Kefnet copies a revealed card cast in
-- response" proves it.
--
-- Nothing for an object with no card behind it (Game.printingIdOfSource): an
-- offer over a copy that cannot be made is not made, which is offerCastOnce's
-- own posture for a reference that named nothing.
castableCopy :: PlayerId -> ObjectId -> Game (Maybe ObjectId)
castableCopy caster original = do
  gs <- State.get
  let found = case Game.lookupObject original gs of
        Just obj -> Just (Just obj, Object.source obj, Object.zone obj)
        Nothing -> case Map.lookup original (GameState.stackArchive gs) of
          Just obj -> Just (Just obj, Object.source obj, Zone.Exile)
          Nothing -> fmap (\known -> (Nothing, LastKnown.source known, LastKnown.zone known)) (Map.lookup original (GameState.lastKnown gs))
  case found of
    Nothing -> pure Nothing
    Just (mObj, source, zone) -> case Game.printingIdOfSource source of
      Nothing -> pure Nothing
      Just printingId -> do
        let (copyId, gs1) = Game.freshObjectId gs
            (ts, gs2) = Game.freshTimestamp gs1
            -- CR 707.12 / 108.2: a copy of a card is no card.
            copy = case mObj of
              Just obj ->
                (Game.setSource (Source.OfCardCopy printingId) (Object.newIncarnation obj))
                  { Object.owner = caster,
                    Object.zone = zone,
                    Object.timestamp = ts,
                    Object.bindings = maybe Map.empty (\pc -> Binding.setOwnCopy pc Map.empty) (Game.copyStampOf obj)
                  }
              Nothing -> Object.new caster (Source.OfCardCopy printingId) zone ts
        State.put (Game.insertIntoZone zone LibraryPosition.Top caster copyId gs2 {GameState.objects = Map.insert copyId copy (GameState.objects gs2)})
        pure (Just copyId)

-- Garth One-Eye's "you still pay its costs": an ordinary cast of the copy.
ordinaryOffer :: CastOffer.CastOffer
ordinaryOffer =
  CastOffer.MkCastOffer
    { CastOffer.transformed = False,
      CastOffer.withoutPayingManaCost = False,
      CastOffer.payingInstead = Nothing,
      CastOffer.spending = ManaSpending.AsProduced,
      CastOffer.restriction = Nothing,
      CastOffer.offeredBy = Nothing,
      CastOffer.faceDown = Nothing,
      CastOffer.payableFromSpent = False,
      CastOffer.reduction = 0
    }

-- CR 615.5: a shield's additional effect, baked with the installing
-- resolution's chosen targets, CR 109.5's "you" and CR 113.7's source, the
-- environment the rider runs in long after that resolution is gone. Nothing for
-- a shield with no rider.
preventionRider :: Map.Map SlotName (Set Recipient) -> PlayerId -> ObjectId -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Maybe PreventionRider.PreventionRider
preventionRider chosen controller source riderEffects =
  if Seq.null riderEffects
    then Nothing
    else
      Just
        PreventionRider.MkPreventionRider
          { PreventionRider.effects = riderEffects,
            PreventionRider.targets = chosen,
            PreventionRider.controller = controller,
            PreventionRider.source = source
          }

-- CR 615.3: install one floating damage row, for a duration. Shared by
-- Effect.PreventNextDamage, Effect.PreventAllDamage,
-- Effect.PreventNextDamageInstance and Effect.RedirectDamage, which differ only
-- in the DamageRewrite and the use count -- CR 615.7's countdown, CR 615.1's
-- unbounded shield, that same shield with CR 614.3's single use beside it (CR
-- 615.8), or CR 614.9's redirection.
--
-- One shield PER RECIPIENT the caller's ObjectRef NAMES, which is why the callers
-- fold this over that set: those recipients were fixed by the resolution (CR
-- 615.11 for an untargeted "each", CR 601.2c for a targeted one), so a shield
-- each is what the rules describe.
--
-- A recipient side the card DESCRIBES instead is the other shape and is not
-- folded: `describedRecipient` below is written onto ONE row, which CR 615.7's
-- "such effects count only the amount of damage; the number of events or sources
-- dealing it doesn't matter" makes a single shared pool over every recipient it
-- admits. Divine Deflection is the countdown's producer, and Parun.Engine.Replacement's
-- rewriteRemaining is where one row spends per point rather than per recipient.
-- CR 615.1's UNBOUNDED shield (Pack Leader) has no amount for that rule to be
-- about, so one row there is simply the row a description needs: with nothing to
-- count down, a row per admitted recipient would prevent exactly the same damage.
--
-- The `rider` is CR 615.5's additional effect, Nothing for a row that has none;
-- a redirection is not a prevention, so RedirectDamage never passes one.
--
-- The folded argument is the row's TWO baked halves, since CR 615.1's shield can
-- be pinned on either side of the damage event: the recipient it covers, and the
-- source it watches. Nothing on a side means EVERY recipient or every source,
-- which is DamagePattern's own reading of the field. Dovin, Hand of Control's
-- "-1: prevent all damage that would be dealt to and dealt BY target permanent"
-- is one row of each, so no row today names both -- nothing here forbids one.
--
-- The source half carries both halves of CR 615.9 -- the printed properties and
-- the id -- so a row cannot be given an id without the recheck that goes with
-- it. That recheck is CR 609.7a's, and a TARGETED source has no properties to
-- recheck (CR 601.2c declared the object itself), so it passes the trivial
-- predicate rather than being exempted from the pairing.
--
-- `printed` is the OTHER way a row can name its source: CR 609.7b's properties,
-- written on the card and asking nobody to choose (Scarecrow's "by creatures
-- with flying"). It reaches the same DamagePattern field as the pair's filter
-- above, so a caller writing both gets their conjunction; `And []` on either
-- side drops out rather than nesting. No card in data/cards/ writes both.
-- Effect.PreventAllDamage and Effect.RedirectDamage (Kjeldoran Royal Guard's
-- "by unblocked creatures") pass a non-trivial one; no printing pairs CR
-- 609.7b's properties with CR 615.7's countdown or CR 615.8's single instance
-- -- Scryfall `o:"prevent the next" o:"sources"`, 2026-08-27, no hit -- so
-- those two opcodes carry no such field.
--
-- `resolving` is the object resolving, which picks the acquisition the duration
-- reads its source's choices under (Expiry.arm, Game.readingAcquisition).
installDamageRow :: ObjectId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set ObjectId) -> PlayerId -> ObjectId -> Duration.Duration -> Maybe DamageKind.DamageKind -> DamageRewrite.DamageRewrite (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Uses.Uses -> Maybe PreventionRider.PreventionRider -> Filter.Type.Filter Keyword.Type.Keyword -> (Maybe (Filter.Type.Filter Keyword.Type.Keyword), Maybe PlayerRelation.PlayerRelation) -> GameState -> (Maybe Recipient, Maybe (Filter.Type.Filter Keyword.Type.Keyword, ObjectId)) -> GameState
installDamageRow resolving targets slots controller source duration kind rewrite uses rider printed describedRecipient g (recipient, sourceChoice) = case Expiry.arm (Game.readingAcquisition resolving source) targets controller source duration g of
  -- CR 611.2b: the duration never started, so no shield is installed.
  Nothing -> g
  Just expiry ->
    let (ts, g1) = Game.freshTimestamp g
        re =
          ReplacementEffect.DamageR
            ( DamageR.MkDamageR
                DamagePattern.MkDamagePattern
                  { -- PRINTED, not assumed: Nothing takes combat and
                    -- noncombat alike, Just Combat only the former.
                    DamagePattern.whichKind = kind,
                    -- A caller that names no source gets the trivial
                    -- predicate, which is CR 615.7's own "the number of
                    -- events or sources dealing it doesn't matter"; one
                    -- that named a CHOSEN source (CR 609.7a) gets that
                    -- source's printed properties, for CR 615.9's recheck
                    -- at the damage event. A caller naming CR 609.7b's
                    -- PRINTED properties instead contributes them here
                    -- too, and the trivial predicate drops out of the
                    -- conjunction rather than nesting inside it.
                    DamagePattern.whatSource = case filter (/= Filter.Type.And []) (printed : Maybe.maybeToList (fmap fst sourceChoice)) of
                      [only] -> only
                      named -> Filter.Type.And named,
                    -- CR 611.2c's DESCRIBED recipient side, disjoined on the
                    -- pattern: a shield covering "you and/or permanents you
                    -- control" is read live at each damage event, since a
                    -- prevention effect changes no characteristic and no
                    -- controller and so reaches objects it did not reach
                    -- when it began. Both halves are Nothing for a row
                    -- whose recipient the resolution BAKED below instead.
                    DamagePattern.whatRecipient = fst describedRecipient,
                    DamagePattern.whoRecipient = snd describedRecipient,
                    DamagePattern.whichRecipient = recipient,
                    -- CR 609.7a's chosen source or CR 601.2c's targeted
                    -- one, baked for the recipient's reason -- both were
                    -- fixed when this effect was created and card data can
                    -- name neither.
                    DamagePattern.whichSource = fmap snd sourceChoice,
                    -- A shield's recipient is already baked, one field up, so
                    -- the slot that would name one has nothing left to say.
                    DamagePattern.boundRecipient = Nothing
                  }
                rewrite
                -- CR 615.5's rider on this carrier is the snapshotted one
                -- on the row below; the authored field here stays empty.
                Seq.empty
            )
        active =
          ActiveReplacement.MkActiveReplacement
            { ActiveReplacement.effect = re,
              ActiveReplacement.source = source,
              -- CR 109.5, baked as Replace's is.
              ActiveReplacement.controller = controller,
              ActiveReplacement.timestamp = ts,
              ActiveReplacement.expiry = expiry,
              -- CR 615.7's shield is spent in DAMAGE, not in applications, so
              -- the use count is not what ends it (see Parun.Types.Uses) and both
              -- countdown callers pass Unlimited. CR 615.8's shield is the one
              -- that passes Once: "once an instance of damage from that source
              -- has been prevented, any subsequent instances ... are dealt
              -- normally" counts APPLICATIONS, which is what this field is.
              ActiveReplacement.uses = uses,
              -- CR 614.15: a self-replacement is one that replaces the damage its
              -- OWN resolution deals, which none of these rows does -- not even
              -- one whose CR 609.7a choice happened to land on this very source.
              ActiveReplacement.origin = ReplacementOrigin.Other,
              -- No clause: the prevention opcodes carry no printed "if" (see
              -- Parun.Types.ActiveReplacement).
              ActiveReplacement.condition = Nothing,
              ActiveReplacement.rider = rider,
              -- The installing resolution's slot bindings, captured here for the
              -- reason Effect.Replace's row captures them (CR 603.7c): this
              -- resolution is about to end, and DamagePattern.whatSource and
              -- DamagePattern.whatRecipient are re-asked at every damage event
              -- (Parun.Engine.Replacement.candidateContext), so a Filter.IsBound in
              -- either would have nothing live to read. The two carriers of a
              -- DamageR row therefore answer a bound slot the same way.
              --
              -- NARROWED to the slots THIS ROW names, not the whole resolution's
              -- map, because the map is also read as CR 609.7a's third class:
              -- referredToSources offers "any object referred to by ... a
              -- replacement or prevention effect that's waiting to apply", and a
              -- slot an unrelated earlier effect of the same resolution bound is
              -- not something this row refers to. The redirection carries no
              -- rider and no clause, but not an empty row: its CR 609.7a
              -- chosen-source predicate is the card's own Filter and folds into
              -- DamagePattern.whatSource, which Synthetic Turn the Blade writes,
              -- and Harm's Way's recipient description rides it as Divine
              -- Deflection's does.
              ActiveReplacement.slots = Map.restrictKeys slots namedSlots,
              -- CR 608.2h: the colour Avacyn, Guardian Angel chose as THIS
              -- resolution ran, under the acquisition it froze (CR 607.5).
              ActiveReplacement.choices = SourceContext.choicesOf (Game.readingAcquisition resolving source g source) source g
            }
        -- Every slot name the row above can name: replacementRowReads' answer for
        -- the ReplacementEffect just built, which is the whole of what
        -- Replacement.candidateContext re-asks it against, plus CR 615.5's rider,
        -- whose objects the effect still refers to even though
        -- Resolve.runPreventionRider reads them off Parun.Types.PreventionRider
        -- rather than off the row. `condition` is Nothing on every one of these
        -- carriers, so it contributes no third half.
        namedSlots = Map.keysSet (replacementRowSlots re) <> foldMap (Map.keysSet . PreventionRider.targets) rider
     in g1 {GameState.replacements = active : GameState.replacements g1}

-- CR 601.2c / 608.2b: an InSlot names the players this resolution's slot holds,
-- baked into Among as the row is installed; every other relation is CR 109.5's
-- and is read as the event happens. A slot naming nobody bakes to nobody.
bakeRelation :: Map.Map SlotName (Set PlayerId) -> ControllerRelation.ControllerRelation -> ControllerRelation.ControllerRelation
bakeRelation players rel = case rel of
  ControllerRelation.InSlot slot -> ControllerRelation.Among (Map.findWithDefault Set.empty slot players)
  ControllerRelation.Related _ -> rel
  ControllerRelation.EnchantedPlayers -> rel
  ControllerRelation.Among _ -> rel

-- CR 611.2c: a combat restriction's stored class, every slot it names baked
-- (Parun.Engine.Filter.bakeBound) since the slots die with this resolution: its
-- players, its objects, and the players related to its objects' controllers
-- through the resolution's own CR 608.2h reader (effectContext). Read live afterwards, so a permanent
-- arriving later is in the class.
storedClass :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> GameState -> Filter.Type.Filter Keyword.Type.Keyword -> Filter.Type.Filter Keyword.Type.Keyword
storedClass legal resolving controller source gs =
  Filter.bakeBound
    (Map.union (Binding.playersIn legal) (Binding.playerSlots bindings))
    (Binding.objectsBySlot legal bindings)
    (fmap related (Filter.slotControllers (effectContext gs resolving controller source legal bindings)))
  where
    bindings = slotBindings resolving gs
    related pids relation = Set.fromList [q | q <- Game.stillPlaying gs, any (\p -> PlayerRelation.holds (Game.teams gs) relation p q) pids]

-- CR 601.2c / 615.12: the same bake one carrier over. A stored CR 615.12 or CR
-- 614.9 prohibition narrows the damage event by a DamagePattern too, and a card
-- that aims its sentence at the recipient its own resolution chose
-- (Whippoorwill's "that creature") writes the SLOT in
-- DamagePattern.boundRecipient; this reads the slot and writes the recipient it
-- named into DamagePattern.whichRecipient, which is what every reader of the
-- pattern already asks about (Parun.Engine.Replacement.matchesDamagePattern).
--
-- ONE PATTERN PER RECIPIENT rather than a set, PreventNextDamage's split for its
-- reason, and an EMPTY answer where the slot named nobody -- CR 608.2b's illegal
-- or unfilled target, which stores no continuous effect at all. A pattern naming
-- no slot is returned unchanged, which is every producer but this one.
--
-- Through Damage.damageRecipient so the baked id is tagged the way the damage
-- event will tag it (CR 120.1a); a slot holding something that can take no damage
-- drops out, and with it the effect.
bakeDamagePatternRecipient :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> GameState -> DamagePattern.DamagePattern -> [DamagePattern.DamagePattern]
bakeDamagePatternRecipient legal resolving controller source gs pattern_ = case DamagePattern.boundRecipient pattern_ of
  Nothing -> [pattern_]
  Just slot ->
    fmap
      (\recipient -> pattern_ {DamagePattern.whichRecipient = Just recipient, DamagePattern.boundRecipient = Nothing})
      (Maybe.mapMaybe (Damage.damageRecipient gs) (objectRefRecipients legal resolving controller source gs (ObjectRef.InSlot slot)))

-- CR 609.7a: choose the SOURCE a prevention or redirection effect names, and
-- answer the pair installDamageRow bakes -- the printed properties beside the id
-- the choice landed on. Nothing for a row naming no source, and Nothing again where the
-- rule's pool held nothing the card's properties admit, which the caller tells
-- apart by whether it passed a Filter at all.
--
-- CHOOSE, not target: rule 609.7a says "a source of your choice", so nothing was
-- declared on the stack (CR 601.2c) and there is no CR 608.2b legality to
-- re-check at the damage event -- CR 615.9 rechecks the source's PROPERTIES
-- instead, which is DamagePattern.whatSource's job and not this one's.
--
-- Asked through Game.chooseAmong.
chooseDamageSource :: PlayerId -> ObjectId -> Filter.Context -> GameState -> Maybe (Filter.Type.Filter Keyword.Type.Keyword) -> Game (Maybe (Filter.Type.Filter Keyword.Type.Keyword, ObjectId))
chooseDamageSource controller resolving context gs filter_ = case filter_ of
  Nothing -> pure Nothing
  Just f -> fmap ((,) f) <$> Game.chooseAmong (\decider who -> Prompt.ChooseDamageSource decider who resolving) controller (damageSourceCandidates context gs f)

-- CR 609.7a's candidate set, its four classes in the rule's own order: "a
-- permanent; a spell on the stack (including a permanent spell); any object
-- referred to by an object on the stack, by a replacement or prevention effect
-- that's waiting to apply, or by a delayed triggered ability that's waiting to
-- trigger (even if that object is no longer in the zone it used to be in); or a
-- face-up object in the command zone", narrowed to the properties the card
-- printed.
--
-- SPELLS on the stack, not the whole zone: the rule says "a spell", and an
-- activated or triggered ability sharing that zone falls under none of the four
-- classes -- it is not a permanent, not a spell, not in the command zone, and
-- nothing refers to it. Game.isSpell asks the object's zone and its KIND, never which
-- card it is -- the same reader ObjectRef.EachSpell above narrows with under CR
-- 109.2b, where the CR 405.1 arm beside it takes the whole zone instead.
--
-- Read off the PROJECTION, so a permanent that is a red source only by a
-- continuous effect is a candidate -- with CR 608.2h's fallback onto last known
-- information, since the third class admits an object "no longer in the zone it
-- used to be in" and a departed id projects blank. Exactly the pair
-- Parun.Engine.Replacement.matchesDamageSource rechecks with under CR 609.7b, so
-- the choice and the recheck cannot read one source two ways.
--
-- The fallback is what Parun.ReplacementSpec's "a departed source is narrowed by
-- its last known information" proves: Synthetic Turn the Blade narrows to Humans
-- and the Ghitu Fire-Eater its controller names has already paid itself as a
-- cost, so under the bare viewOfObject it satisfies no subtype filter, is never
-- offered, and the redirection watches a source nobody chose.
--
-- DEDUPED, the classes overlapping wherever a spell's living target is also a
-- permanent, and ASCENDING out of the same Set, so both the single-candidate
-- shortcut and a transcript are deterministic -- Parun.Engine.Blight's posture.
damageSourceCandidates :: Filter.Context -> GameState -> Filter.Type.Filter Keyword.Type.Keyword -> [ObjectId]
damageSourceCandidates context gs filter_ =
  let faceUp oid = fmap Object.facing (Game.lookupObject oid gs) == Just Facing.FaceUp
      viewOf oid = Maybe.fromMaybe (Projection.viewOfObject oid gs) (Projection.viewWithLastKnownAnywhere gs oid)
      pool =
        Set.fromList
          ( Set.toList (GameState.battlefield gs)
              <> filter (\oid -> Game.isSpell oid gs) (GameState.stack gs)
              <> referredToSources gs
              <> filter faceUp (Set.toList (GameState.command gs))
          )
   in filter (\oid -> Filter.matches context (viewOf oid) filter_) (Set.toAscList pool)

-- CR 609.7a's third class, off the three carriers the sentence names: every
-- object on the stack, every row of GameState.replacements waiting to apply, and
-- every entry of GameState.delayedTriggers waiting to trigger. What each REFERS
-- TO is the object it names as its source plus the objects its bindings or slots
-- hold -- Ghitu Fire-Eater's ability naming the creature its own cost
-- sacrificed, a shield naming "that creature", a delayed trigger naming "it".
--
-- The SOURCE counts as a referent for all three: CR 113.7a says an ability that
-- causes a source to do something checks that source's information when it
-- resolves, and a waiting row's own condition and pattern are evaluated in a
-- Filter.Context built on its source (Parun.Engine.Replacement.collect), so each
-- of the three can genuinely name it.
--
-- NO ZONE TEST anywhere in here, which is the clause's point: an id that names
-- nothing is exactly the case the parenthesis admits, and damageSourceCandidates
-- reads it through CR 608.2h's last known information rather than through the
-- blank view a live-only projection gives.
--
-- A waiting ROW refers to three things, and the fold below is over all three
-- rather than over a whole resolution's bindings: its source, the SLOTS its own
-- pattern and rewrite name -- which is all its captured map now holds, since
-- installDamageRow and the Effect.Replace resolution arm restrict what they
-- capture to replacementRowSlots, and Parun.ReplacementSpec's Synthetic Parting
-- Ward and Galvanic Blast cases read that narrowing -- and the ids a resolution
-- BAKED into it, which no Filter and no slot map holds (referentsOfReplacement).
--
-- Every carrier is proven in the OFFERING direction, each by one
-- Parun.ReplacementSpec case: the STACK's by "a source only a waiting ability
-- still refers to is offered" (Ghitu Fire-Eater under Auriok Replica), the ROW's
-- baked ids by the Healing Grace case beside it, the row's captured SLOTS by
-- Synthetic Communal Bulwark's under Healing Grace, and the DELAYED TRIGGER's
-- bindings by Come Back Wrong's under Auriok Replica. A spend trigger's source is
-- a fence: Pyromancer's Goggles deals no damage, and leaving while its mana
-- floats is the only way it is not already a candidate.
--
-- The two binding-reading carriers -- the stack's and the delayed trigger's -- also
-- share one EXCLUSION, stated once at referentsOfBindings below rather than at each
-- of them: an activated ability's own id is not something it refers to.
referredToSources :: GameState -> [ObjectId]
referredToSources gs =
  foldMap (\oid -> foldMap referentsOfObject (Game.lookupObject oid gs)) (GameState.stack gs)
    <> foldMap (\row -> ActiveReplacement.source row : (referentsOfReplacement (ActiveReplacement.effect row) <> foldMap Set.toList (ActiveReplacement.slots row))) (GameState.replacements gs)
    <> foldMap (\entry -> DelayedTrigger.source entry : referentsOfBindings (DelayedTrigger.bindings entry)) (GameState.delayedTriggers gs)
    -- CR 106.6a's spend triggers wait on the unspent units that carry them.
    <> foldMap (Maybe.mapMaybe (fmap SpendTrigger.source . ManaUnit.spendTrigger) . Mana.Type.unwrap) (GameState.manaPool gs)

-- The objects a waiting row names BY ID: what card data cannot write, so what no
-- Filter and no captured slot holds, and what CR 609.7a's "any object referred to
-- by ... a replacement or prevention effect that's waiting to apply" reaches only
-- through here. Only the damage arm has any -- CR 609.7a's chosen source or CR
-- 601.2c's targeted one, CR 611.2c's named recipient, and CR 614.9's baked
-- destination -- and each is written as a resolution installs the row
-- (installDamageRow), a card's own redirection naming its destination by
-- description instead (DamageRewrite.RedirectMatching, Pariah). Each is exactly
-- the rule's parenthetical case, an object that may no longer be in the zone it
-- used to be in.
--
-- PLAYER recipients drop out, referentsOfBindings' reason: the rule's four classes
-- are all objects.
--
-- No wildcard: an arm of Parun.Types.ReplacementEffect that later bakes an id must
-- answer here, or its object silently leaves the pool. Every arm answering []
-- names things by Filter and by slot alone, which replacementRowSlots reports.
referentsOfReplacement :: ReplacementEffect.ReplacementEffect card ability effect -> [ObjectId]
referentsOfReplacement re = case re of
  ReplacementEffect.ZoneChangeR _ -> []
  ReplacementEffect.EntryR _ -> []
  ReplacementEffect.DamageR (DamageR.MkDamageR pat rewrite _) ->
    Maybe.maybeToList (DamagePattern.whichSource pat)
      <> Maybe.mapMaybe Recipient.objectOf (Maybe.maybeToList (DamagePattern.whichRecipient pat) <> damageRewriteRecipients rewrite)
  ReplacementEffect.DestructionR _ -> []
  ReplacementEffect.CounterR _ -> []
  ReplacementEffect.TokenR _ -> []
  ReplacementEffect.TurnUpR _ -> []
  ReplacementEffect.AttachR _ -> []
  ReplacementEffect.UntapR _ -> []
  ReplacementEffect.LifeLossR _ -> []
  ReplacementEffect.LifeGainR _ -> []
  ReplacementEffect.DrawR _ -> []
  ReplacementEffect.DrawCountR _ -> []
  ReplacementEffect.InstructionR _ -> []
  ReplacementEffect.DieRollR _ -> []
  ReplacementEffect.AssembleR _ -> []
  ReplacementEffect.ManaR _ -> []
  ReplacementEffect.GameLossR _ -> []
  ReplacementEffect.PlaneswalkR _ -> []
  ReplacementEffect.PhaseR _ -> []

-- The recipients a damage REWRITE bakes, which is CR 614.9's redirect destination
-- and nothing else. damageRewriteReads' discipline (Parun.Engine.Resolve.Slots):
-- no wildcard, so a later rewrite naming a recipient must answer here.
damageRewriteRecipients :: DamageRewrite.DamageRewrite effect -> [Recipient]
damageRewriteRecipients rewrite = case rewrite of
  DamageRewrite.RedirectMatching _ -> []
  DamageRewrite.Redirect recipient -> [recipient]
  DamageRewrite.RedirectNext _ recipient -> [recipient]
  DamageRewrite.PreventAll -> []
  DamageRewrite.PreventRemovingShieldCounter -> []
  DamageRewrite.PreventNext _ -> []
  DamageRewrite.PreventAllBut _ -> []
  DamageRewrite.PreventUpTo _ -> []
  DamageRewrite.SetAmount _ -> []
  DamageRewrite.Scale _ -> []
  -- The nested effects name objects through SLOTS rather than baked ids, and
  -- Parun.Engine.Resolve.Slots' replacementRowSlots is what reports those.
  DamageRewrite.RunEffects _ -> []
  -- The row's own permanent is its source, which is no baked id of the rewrite's.
  DamageRewrite.TurnFaceUp -> []

-- What one object on the stack refers to: its CR 113.7 source object, and every
-- object its bindings name.
referentsOfObject :: Object.Object -> [ObjectId]
referentsOfObject obj = sourceObjectOf (Object.source obj) <> referentsOfBindings (Object.bindings obj)

-- The object a Source names, and TOTAL over every arm rather than two and a
-- wildcard: a future arm that names an object owes this list a line, and `_`
-- would swallow it. Only the two on-stack ability arms name one -- CR 113.7's
-- "the object whose ability was activated" and "the object whose ability
-- triggered". The card-shaped arms ARE the object rather than naming another --
-- a melded permanent included, CR 701.42a making it one object however many
-- cards represent it -- and CR 725.2's inherent trigger has no object source at
-- all, which is the whole of what distinguishes it from OfTrigger.
sourceObjectOf :: Source.Source -> [ObjectId]
sourceObjectOf src = case src of
  Source.OfCard _ -> []
  Source.OfMeld _ -> []
  Source.OfMerge _ -> []
  Source.OfToken _ -> []
  Source.OfAbility a -> [ActivatedAbilitySource.source a]
  Source.OfTrigger t -> [TriggeredAbilitySource.source t]
  Source.OfEmblem _ -> []
  Source.OfSpellCopy _ -> []
  Source.OfCardCopy _ -> []
  Source.OfInherentTrigger _ -> []

-- Every object a binding environment names (Parun.Engine.Binding.slotObjects):
-- every target a slot holds (CR 601.2c) and every member of a group a clause
-- defines without targeting it (CR 115.10a) -- a spell that targets two
-- creatures refers to both of them, and CR 609.7a asks for every object
-- referred to. Player recipients drop out, the rule's classes all being objects.
--
-- TWO SLOTS ARE DROPPED, by NAME rather than by comparing ids. Binding.thisAbility
-- holds the ability's OWN id (CR 602.2a, 603.3), which parun stamps so a card can
-- read the ability's own record -- the mana that paid for an activation, and how
-- many times it has resolved this turn -- not because any printed text names the ability as
-- another object. Counting it would undo CR 609.7a's second class, which admits "a
-- spell on the stack" and deliberately stops short of an ability.
--
-- HERE rather than at the carriers, because two of CR 609.7a's three read bindings
-- and both were wrong: `referentsOfObject` for an ability still on the stack, and
-- Effect.ArmDelayedTrigger's captured environment for one that has already ceased,
-- which is unrestricted by design (CR 603.7c). The third carrier reads
-- ActiveReplacement.slots, already narrowed to the row's own slot names, so it
-- never sees this one unless a card writes it -- and then the card really does name
-- it. Parun.ReplacementSpec proves both binding carriers, one case each.
--
-- Binding.announcedTargets is dropped too: it repeats the targets the target
-- slots already name.
--
-- Binding.collectedEvidence is the SECOND slot dropped, for the same kind of
-- reason: it records whether evidence was collected, which is all CR 701.59c's
-- linked text asks, and no text names the exiled cards through it.
-- Parun.CostSpec's "CR 609.7a the evidence the Inspector collected is not a
-- source it refers to" proves it. The other paid-cost slots stay, whether or
-- not the effect reads them again: the cost's own words refer to the object it
-- paid with ("Sacrifice a creature", "Discard a creature card"), and the
-- ability on the stack carries that text. Fling and Necromancer's Stockpile
-- read theirs again; Cho-Arrim Alchemist's discarded card is a source it
-- refers to all the same.
referentsOfBindings :: Map.Map SlotName Binding.Type.Binding -> [ObjectId]
referentsOfBindings bindings =
  let named = Map.withoutKeys bindings (Set.fromList [Binding.thisAbility, Binding.collectedEvidence, Binding.announcedTargets])
   in foldMap Set.toList (Binding.slotObjects named)

-- CR 608.2h for an entry rider's counts: the card writes a Quantity per counter
-- kind (CR 122.6, CR 107.3c -- Printlifter Ooze's "X +1/+1 counters on it, where
-- X is the number of other creatures you control"), and the funnel takes settled
-- numbers. This is the ONE bridge between the two, so the answer is determined
-- once, when the effect is applied, and nothing downstream can re-read the board.
--
-- Against the CALLER'S OWN context, which is the resolution's. Evaluating here
-- rather than at the funnel is what keeps that available: Event.createTokens and
-- Event.changeZoneEntering have no context and no view to hand, so one built
-- there would be a Filter.contextFor with an empty slot map and no source --
-- Filter.IsBound false, Filter.IsSource false and a Quantity.AgainstSlot
-- unanswered, none of which raises anything.
--
-- CR 107.2 for an unevaluable count and CR 107.1b for a negative one, both zero;
-- a zero-count kind is DROPPED rather than passed on, so CR 614.16's replacements
-- are never offered an event that places no counter.
freezeRiders ::
  (ObjectId -> Maybe Filter.View) ->
  Filter.Context ->
  GameState ->
  ObjectId ->
  ObjectId ->
  EntryRiders.EntryRiders Quantity.Type.Quantity ability ->
  EntryRiders.EntryRiders Natural ability
freezeRiders viewOf context gs resolving source riders =
  let frozen quantity = case Quantity.evaluateFor viewOf context gs resolving source quantity of
        Just n | n > 0 -> Just (Integer.toNaturalSaturating n)
        _ -> Nothing
   in riders
        { EntryRiders.counters = Map.mapMaybe frozen (EntryRiders.counters riders),
          -- CR 608.2h / 611.2d, ModifyTarget's freeze: a quantity that cannot
          -- be evaluated now leaves its effect unstored.
          EntryRiders.characteristics = Seq.fromList (Maybe.mapMaybe (Projection.freezeQuantities viewOf gs resolving source context) (Foldable.toList (EntryRiders.characteristics riders)))
        }

-- The amount ONE RECIPIENT of a per-player instruction reads, which need not be
-- the amount the rest of the table reads (Stronghold Discipline). Every opcode
-- naming a set of players and an amount evaluates through here, once per
-- recipient. For Effect.DealDamage the set may hold objects too, and
-- recipientSeat is what says whose an object's amount is.
--
-- Two spellings, because a card asks two different questions: Filter.Context's
-- `recipient`, which Filter.HeldByRecipient reads
-- (see #161); and
-- Quantity.forCandidate, which substitutes PlayerRef.Candidate. Both are no-ops
-- for a quantity naming neither, so this is no departure from CR 608.2f's single
-- determination -- every amount is read off the same pre-effect GameState.
evaluateForRecipient ::
  (ObjectId -> Maybe Filter.View) ->
  Filter.Context ->
  GameState ->
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Quantity.Type.Quantity ->
  Maybe Integer
evaluateForRecipient viewOf context gs announcedOn source pid quantity =
  Quantity.evaluateFor
    viewOf
    (context {Filter.recipient = Just pid})
    gs
    announcedOn
    source
    (Quantity.forCandidate pid quantity)

-- The objects a slot holds as a BINDING: the whole GROUP an earlier effect of
-- this resolution bound, or the single object bound in its place -- the two
-- shapes every binder dispatches between on how many objects it named. Nothing
-- where the slot holds neither, which the MoveToZone InSlot gather reads as
-- "then look at the targets".
--
-- Read AHEAD of the caller's legal-target map: a group binding is a definition,
-- never a target (CR 115.10a), so it owes CR 608.2b nothing. `slotOne` and not
-- objectRefObjects, since slotOne is what lets a slot an EARLIER EFFECT OF THIS
-- SAME RESOLUTION bound name its object here; a slot the `chosen` map mentions
-- was targeted, so it is left to the target path behind CR 608.2b's
-- re-validation.
slotBoundObjects :: ObjectId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game (Maybe [ObjectId])
slotBoundObjects resolving chosen slot = do
  group <- State.gets (slotGroup slot resolving)
  case group of
    -- Mint order, which CR 608.2f leaves standing.
    Just objects -> pure (Just (Foldable.toList objects))
    Nothing -> do
      bound <- if Map.member slot chosen then pure Nothing else State.gets (slotOne slot resolving)
      pure (fmap (: []) bound)

-- The members a "from among them" slot offers: the GROUP an earlier effect of
-- this resolution bound, the SINGLE object bound in its place, or -- where the
-- slot was targeted rather than defined -- every recipient CR 608.2b left legal.
-- slotBoundObjects with the last of those three added, which is the InSlot
-- gather's own read; the three callers share it so the matched half, the chosen
-- card and "the rest" cannot see different groups.
--
-- The third case is not decoration: a reveal or a look that named exactly ONE
-- card binds the singular shape, which slotBoundObjects reports only while the
-- slot is absent from `chosen` -- and the per-effect re-read of Object.bindings
-- (CR 608.2c) puts it there. Without the fallback, Commune with the Gods over a
-- one-card library would offer nothing and bury the card.
fromAmongMembers :: Map.Map SlotName (Set Recipient) -> ObjectId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game [ObjectId]
fromAmongMembers legal resolving chosen slot = do
  bound <- slotBoundObjects resolving chosen slot
  pure $ case bound of
    Just objects -> objects
    Nothing -> Maybe.mapMaybe Recipient.objectOf (legalMany slot legal)

-- CR 723.1a: the new control is the last one CREATED, so it goes ON TOP of any
-- control already running on that player rather than replacing it. That rule's
-- "overwrite" is the continuous-effect sense -- both effects exist and the later
-- one works -- so a Word of Command cast at a player Mindslaver already controls
-- layers over the CR 723.1 row, and Parun.Engine.Stack's lapse hands that row
-- back; see #3351.
--
-- The stack is kept in creation order, so appending is what "last created"
-- means and Parun.Engine.Decide.effective reads the end of it.
pushControl :: PlayerId -> PlayerControl.PlayerControl -> GameState -> GameState
pushControl pid row gs =
  let after new old = old <> new
   in gs {GameState.control = Map.insertWith after pid (pure row) (GameState.control gs)}

-- pushControl's inverse for a row its installer lifts itself: the latest
-- matching row goes, and a player left with none loses the key.
popControl :: PlayerId -> PlayerControl.PlayerControl -> GameState -> GameState
popControl pid row gs =
  let lift rows = NonEmpty.nonEmpty (reverse (List.delete row (reverse (NonEmpty.toList rows))))
   in gs {GameState.control = Map.update lift pid (GameState.control gs)}

-- Opposition Agent's "they exile each card they find": the cards a search put
-- into exile in place of its own destination are linked to the object whose
-- row exiled them (CR 607.1c), not to the searching ability, whose
-- recordExiledWith keeps a link already filed. Bound to no slot: the ruling
-- has an instruction naming the found cards fail to see them in exile.
--
-- The same sentence's "you may play those cards for as long as they remain
-- exiled, and you may spend mana as though it were mana of any color to cast
-- them": a permission on each card (CR 601.3) for the Agent's controller as
-- the card is exiled, with CR 609.4b's rider. On the card rather than read off
-- the Agent, since it outlasts the Agent and ends only as the card leaves
-- exile (CR 400.7).
exileFoundFor :: ObjectId -> Seq.Seq ObjectId -> Game ()
exileFoundFor agent exiled =
  State.modify' $ \gs ->
    let link = ExileLink.MkExileLink {ExileLink.source = agent, ExileLink.ability = Nothing}
        file oid = Map.insert oid link
        permission you = (ExilePlayPermission.defaultValue you agent) {ExilePlayPermission.spending = ManaSpending.AnyColor}
        grant you o = o {Object.playableFromExile = Just (permission you)}
        granted = case Projection.controllerOf agent gs of
          Just you -> foldr (Map.adjust (grant you)) (GameState.objects gs) exiled
          Nothing -> GameState.objects gs
     in gs {GameState.exiledWith = foldr file (GameState.exiledWith gs) exiled, GameState.objects = granted}

-- CR 723.1 / 805.8: the players an effect making `controller` control `target`
-- reaches -- `target`, and under the shared team turns option each of their
-- teammates but `controller`, who cannot be made to control themselves through
-- their team. `target` itself stays even when it is `controller`, which is CR
-- 723.1a's way of taking one's own decisions back.
controlledTeam :: PlayerId -> PlayerId -> GameState -> [PlayerId]
controlledTeam controller target gs =
  filter (\pid -> pid == target || (pid /= controller && Turn.sharesTurn gs target pid)) (GameState.turnOrder gs)

-- CR 402.3 with a CR 608.2d choice: each hand the reference names is offered to
-- its OWN owner (a hand's cards are that player's alone), who picks the ref's
-- count of DISTINCT cards matching the filter, each pick dropped from the
-- candidates before the next ask (CR 608.2d). The candidates are read as the
-- instruction is reached (CR 608.2c), the asks run in APNAP order (CR 608.2e,
-- CR 101.4) through handChoosers, through Game.chooseAmong (CR 101.3, CR 609.3).
-- Every card comes back in ONE list, so the instruction moves them as one event
-- (CR 608.2f) -- proved by the scenario "CR 608.2f Aquatic Subtlety bottoms its
-- two cards in one event".
--
-- askingObjects' ChosenCardInHand arm.
chooseCardsInHand ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  ChosenCardInHand.ChosenCardInHand ->
  Game [ObjectId]
chooseCardsInHand resolving source controller legal (ChosenCardInHand.MkChosenCardInHand player filter_ count) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      wanted = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source count)
      pick asked n candidates
        | n <= (0 :: Natural) = pure []
        | otherwise = do
            picked <- Game.chooseAmong (\decider who -> Prompt.ChooseCardInHand decider who source) asked candidates
            case picked of
              Nothing -> pure []
              Just taken -> (taken :) <$> pick asked (n - 1) (List.delete taken candidates)
  fmap concat . Monad.mapM (\pid -> pick pid wanted (handCardsOf context gs pid filter_)) $
    handChoosers legal resolving source controller gs player

-- The printed "from among them", a CR 608.2d choice: the candidates are the
-- members of a GROUP an earlier clause of this resolution bound rather than a
-- zone's contents, which is the whole difference from the zone-keyed choices --
-- and the reason a batch CR 701.20a's reveal or CR 701.20e's look left in the
-- LIBRARY is reachable at all (CR 701.20b), a library's filtered sweep naming
-- every match in the whole zone rather than that handful.
--
-- ONE function rather than one per opcode, because it is ONE choice: Carth the
-- Lion's "you may reveal a planeswalker card from among them and put it into
-- your hand" reveals and moves the SAME card, so the reveal asks this and binds
-- what it showed, and the move reads that binding. Two opcodes each asking their
-- own would be two independent choices, which the printed "and" forbids.
--
-- The candidates are read from the state the instruction is reached in (CR
-- 608.2c) through slotBoundObjects, so every reader of the group sees the same
-- members. Narrowed by the ref's own Filter, matched in THIS EFFECT's context (CR
-- 109.5's "you" is the resolving controller), against the CR 613 projection -- so
-- a card a continuous effect made a creature is a creature card here.
--
-- WHO is asked is the ref's own chooser, ONE seat: CR 608.2c's resolving
-- controller by default, or the seat a PlayerRef names -- Animal Magnetism's "an
-- opponent chooses a creature card from among them", a seat the controller
-- names. Read through askedChooser, so a slot is read as every other is (CR
-- 608.2b), a reference naming nobody asks nobody and so names no card (CR
-- 101.3), CR 801.5c hands the choice to the nearest opponent where none is in
-- range, and CR 800.4g hands it on where the seat it names has left the game.
--
-- HOW MANY is the ref's count, read HERE (CR 608.2c) off the announcement CR
-- 601.2b left on the resolving object -- TopOfLibrary's reading, and its clamp: a
-- count that will not evaluate, or evaluates negative, is zero cards (CR
-- 107.1b). pickCounted asks it.
chooseCardFromAmong ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  Map.Map SlotName (Set Recipient) ->
  ChosenCardFromAmong.ChosenCardFromAmong ->
  Game [ObjectId]
chooseCardFromAmong resolving source controller legal chosen (ChosenCardFromAmong.MkChosenCardFromAmong slot filter_ count chooser pileChooser) = do
  members <- fromAmongMembers legal resolving chosen slot
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      amount = maybe 0 Integer.toNaturalSaturating . Quantity.evaluateFor viewOf context gs resolving source
      matching = matchingFromAmong legal resolving controller source gs filter_ (stillPresent gs members)
      pick purpose =
        pickByChooser
          resolving
          source
          controller
          legal
          chooser
          (\decider who -> Prompt.ChooseCardFromAmong decider who source)
          (\decider who pool ceiling_ -> Prompt.ChooseAnyNumber decider who source purpose pool ceiling_)
          amount
          count
  case pileChooser of
    Nothing -> pick AnyNumberOf.CardsFromAmong matching
    -- CR 700.3: the chooser separates and the pile chooser takes a pile --
    -- Fact or Fiction. Proved by the scenario "CR 700.3 Sphinx of Uthuun".
    Just pileRef -> do
      split <- case matching of
        [_] -> pure matching
        _ -> pick AnyNumberOf.IntoPile matching
      takePile resolving source controller legal pileRef matching split

-- CR 700.3: the separating player's pick is one pile and the rest of the
-- matching objects the other (CR 700.3a), either possibly empty (CR 700.3d),
-- and the seat the ref names takes one, which is what this answers. A single
-- object splits only one way, so callers do not ask its separation; piles alike
-- (none matched) are not offered either. A ref naming nobody takes nothing (CR
-- 101.3).
takePile :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> [ObjectId] -> [ObjectId] -> Game [ObjectId]
takePile resolving source controller legal pileRef matching split = do
  let first = Set.fromList split
      rest = Set.difference (Set.fromList matching) first
      piles = if rest == first then [first] else [first, rest]
  seat <- askedChooser resolving source controller legal pileRef
  taken <- case seat of
    Nothing -> pure Nothing
    Just who -> Game.chooseAmong (\decider asked -> Prompt.ChoosePile decider asked source) who piles
  pure (foldMap Set.toList taken)

-- CR 701.20a / 701.9b: the cards randomness names out of each hand the ref
-- reaches -- askingObjects' RandomCardInHand arm (Fall, Hymn to Tourach, Elkin
-- Lair).
--
-- The question goes to the INTERPRETER: the engine does not roll and no player
-- picks. Filtered rather than trusted, so an answer naming a card never offered
-- falls back to the head of the offer. Game.ask and not Game.choose, since
-- randomness is not CR 104.4b's optional action.
--
-- Elided at one candidate and skipped at none (CR 101.3, CR 609.3). Candidates
-- are the hand as CR 608.2c reaches it in the zone's own order (CR 402.3)
-- narrowed by the ref's own Filter, and the seats come from handChoosers so the
-- asks run in CR 608.2e's APNAP order.
--
-- The count names DISTINCT cards -- "two cards at random" is two cards and not
-- two picks that may coincide -- so each card named is dropped from the
-- candidates before the next ask. CR 609.3 caps the run at the hand's matching
-- size.
randomCardsInHand ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  RandomCardInHand.RandomCardInHand ->
  Game [ObjectId]
randomCardsInHand resolving source controller legal (RandomCardInHand.MkRandomCardInHand player filter_ count) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      wanted = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source count)
  fmap concat . Monad.mapM (\pid -> Game.drawDistinct Prompt.RandomObject wanted (handCardsOf context gs pid filter_)) $
    handChoosers legal resolving source controller gs player

-- CR 404.1 / 608.2c: the cards randomness names out of each graveyard the ref
-- reaches -- askingObjects' RandomCardInGraveyard arm.
--
-- randomCardsInHand's posture over a PUBLIC zone (CR 400.2), and the differences
-- all follow from that: the graveyards come from a ZoneScope rather than from
-- handChoosers, since CR 402.3's bar on looking at another player's hand has no
-- counterpart over a graveyard.
--
-- Unchanged from that function: the question goes to the INTERPRETER rather than
-- to a player or to a roll the engine makes, the answer is FILTERED against the
-- offer rather than trusted, Game.ask and not Game.choose (randomness is not CR
-- 104.4b's optional action), elided at one candidate and skipped at none (CR
-- 101.3, CR 609.3), and the count names DISTINCT cards, so each card named is
-- dropped from the candidates before the next ask.
randomCardsInGraveyard ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  RandomCardInGraveyard.RandomCardInGraveyard ->
  Game [ObjectId]
randomCardsInGraveyard resolving source controller legal (RandomCardInGraveyard.MkRandomCardInGraveyard scope filter_ count) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      wanted = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source count)
  fmap concat . Monad.mapM (\pid -> Game.drawDistinct Prompt.RandomObject wanted (graveyardCardsOf context gs pid filter_)) $
    Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) legal scope gs

-- Alchemy's seek: the cards randomness names out of each library the ref
-- reaches -- askingObjects' RandomCardInLibrary arm.
--
-- randomCardsInHand's posture one hidden zone over, seats and all
-- (handChoosers). What seek's Arena text leaves out is the point: nobody
-- looks at the library, nothing is revealed and nothing is shuffled, so this
-- asks the interpreter and nothing else.
randomCardsInLibrary ::
  ObjectId ->
  ObjectId ->
  PlayerId ->
  Map.Map SlotName (Set Recipient) ->
  RandomCardInLibrary.RandomCardInLibrary ->
  Game [ObjectId]
randomCardsInLibrary resolving source controller legal (RandomCardInLibrary.MkRandomCardInLibrary player filter_ count) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      wanted = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source count)
  fmap concat . Monad.mapM (\pid -> Game.drawDistinct Prompt.RandomObject wanted (libraryCardsOf context gs pid filter_)) $
    handChoosers legal resolving source controller gs player

-- CR 702.167c: the cards exiled to pay the cost of the craft ability resolving
-- as `resolving` (Binding.craftMaterials), linked to the permanent it put onto
-- the battlefield as `entered`, under Binding.craftLink so the craft readers
-- (ExiledPile.CraftMaterials)
-- tell them from what that permanent's other abilities exile. Only those still
-- in exile, which is the rule's "cards in exile". Parun.ActivateSpec's
-- Mastercraft Raptor case is the proof.
linkCraftMaterials :: ObjectId -> ObjectId -> GameState -> GameState
linkCraftMaterials resolving entered gs =
  let paid = foldMap Set.toList (Map.lookup Binding.craftMaterials (Binding.targetsOf (slotBindings resolving gs)))
      materials = filter (`Set.member` GameState.exile gs) (Maybe.mapMaybe Recipient.objectOf paid)
      link = ExileLink.MkExileLink {ExileLink.source = entered, ExileLink.ability = Just Binding.craftLink}
   in gs {GameState.exiledWith = foldr (`Map.insert` link) (GameState.exiledWith gs) materials}

-- CR 607.2a's link, filed as the instruction that made it finishes: every card
-- that ARRIVED in exile while the effect ran is filed against that effect's
-- source and the ability's name.
--
-- A DIFFERENCE over GameState.exile rather than a case over the opcode: CR
-- 607.2a asks whether an ability's instruction exiled the card, never which
-- instruction, so the rules core stays off effect identity. New IDS and not new
-- cards, so an arrival cannot be confused with a card already in exile (CR
-- 400.7). The INNERMOST filing wins, which is what insertWith keeps, since
-- applyEffectWith recurses. Then RESTRICTED to what is still in exile, so the
-- map cannot grow over a game.
--
-- What insertWith ALSO keeps is CR 614.14's link, which Parun.Engine.Event's
-- EntryRewrite.ExileFromGraveyard arm files as the entry replacement applies --
-- inside this window, since the permanent enters as a spell resolves, and the
-- card belongs to the entering permanent rather than to that spell (Living
-- Lore). It keeps CR 607.2b's link the same way, which Parun.Engine.Event files
-- at the move itself: a card this window saw arrive because somebody else's
-- replacement effect redirected it there was not put in exile by an instruction
-- in the resolving ability, so 607.2a does not claim it and this diff must not
-- overwrite the funnel's entry with `source`. Load-bearing, not incidental --
-- Parun.ZoneTriggerSpec's "CR 607.2b the card Rest in Peace's replacement exiles
-- is linked to IT" is what proves it.
--
-- Filed for a SPELL's effects too, where CR 607.2a scopes the link to an
-- activated or triggered ability -- unreadable rather than wrong, since CR
-- 608.2n puts the spell into its graveyard as part of its own resolution.
recordExiledWith :: ExileLink.ExileLink -> Set ObjectId -> GameState -> GameState
recordExiledWith link before gs =
  let arrived = Set.difference (GameState.exile gs) before
      file oid = Map.insertWith (\_ inner -> inner) oid link
   in gs {GameState.exiledWith = Map.restrictKeys (foldr file (GameState.exiledWith gs) arrived) (GameState.exile gs)}

-- CR 406.4's separate piles, filed off the same window: "face-down cards in exile
-- should be kept in separate piles based on when they were exiled and how they
-- were exiled", so every card that arrived in exile FACE DOWN while one effect
-- ran shares one stamp, and the next effect's arrivals get another.
--
-- That window is the rule's two criteria at once, and is why the stamp is taken
-- here rather than in Parun.Engine.Event's zone-change funnel: the funnel moves
-- one card, so a stamp minted there would put every card in a pile of its own --
-- and a pile of one is a card the chooser has effectively named, which is the
-- direction rule 406.4 exists to forbid. One EXECUTION of one instruction is
-- "when", and its being that instruction is "how".
--
-- A difference over GameState.exile and not a case over the opcode,
-- recordExiledWith's road above and for its reason: the rules core stays off
-- effect identity.
--
-- Only cards NOT already stamped, which is what makes a nested application's
-- filing stand -- applyEffectWith recurses, so the innermost window is the one
-- that ran the instruction, and the outer one must not re-pile what it saw
-- arrive. That gate is also what keeps the timestamp supply still: no stamp is
-- drawn by an effect that exiled nothing face down.
--
-- The nesting half of it is a regression fence rather than proven behaviour: no
-- card in `data/cards/` exiles face down from inside another effect, so dropping
-- the gate leaves the suite green. The supply half is proved by every board that
-- exiles nothing face down.
--
-- Then RESTRICTED to what is still in exile, recordExiledWith's sweep: CR 400.7
-- gives a card that left a new id, so the old key can never be named again.
recordExilePile :: Set ObjectId -> GameState -> GameState
recordExilePile before gs =
  let kept = Map.restrictKeys (GameState.exilePiles gs) (GameState.exile gs)
      unstamped =
        filter
          (\oid -> not (Map.member oid kept) && maybe False Object.exiledFaceDown (Game.lookupObject oid gs))
          (Set.toList (Set.difference (GameState.exile gs) before))
   in case unstamped of
        [] -> gs {GameState.exilePiles = kept}
        _ ->
          let (stamp, gs1) = Game.freshTimestamp gs
           in gs1 {GameState.exilePiles = foldr (\oid -> Map.insert oid stamp) kept unstamped}

-- CR 724.1b: how one object leaves the stack when an effect ends the turn. A card
-- or a token is EXILED, which is a zone change like any other; an ability is not
-- represented by a card, so it ceases to exist instead (Game.cease, CR 608.2n's
-- own mechanism) rather than being filed into exile as a phantom that rule
-- 724.1b's second sentence expects the next check to remove and that
-- Parun.Engine.Sba's cease pass would not.
--
-- A COPY OF A SPELL is exiled with the cards, and rule 724.1b's second sentence
-- is why it may be: CR 704.5e removes it at the next check, which is the same
-- pass CR 704.5d makes for a token. Ceasing it here instead would be the same end
-- state reached without the zone change the rule asks for. CR 707.10a's other
-- copy -- CR 722.3c's cast copy of a card -- takes the same arm for the same two
-- sentences.
--
-- TOTAL over every Source arm rather than three and a wildcard, because rule
-- 724.1b's first sentence is about EVERY object on the stack: a new kind of
-- stack object owes this list a line, and `_` swallowed one once already
-- (Source.OfCardCopy, added by #3377 and answered wrongly until #3379).
exileOrCease :: ObjectId -> Game ()
exileOrCease oid = do
  gs <- State.get
  let cease :: Game ()
      cease = State.modify' (Game.cease oid)
  case fmap Object.source (Game.lookupObject oid gs) of
    Just (Source.OfCard _) -> Event.changeZone oid Zone.Exile
    Just (Source.OfToken _) -> Event.changeZone oid Zone.Exile
    Just (Source.OfSpellCopy _) -> Event.changeZone oid Zone.Exile
    -- A REGRESSION FENCE rather than a proven behaviour: ceasing the copy in
    -- place reaches the same end state, since CR 724.1c's check would remove it
    -- from exile anyway (CR 704.5e), and no card in data/cards/ watches an object
    -- entering exile in a way that could tell the two apart -- mutating this arm
    -- to `cease` leaves the suite green. It is written the rule's way because CR
    -- 724.1b says "exile every object on the stack", not because a test pays for
    -- it.
    Just (Source.OfCardCopy _) -> Event.changeZone oid Zone.Exile
    -- Not represented by a card, so rule 724.1b's second sentence would remove
    -- them at CR 724.1c's check anyway; Game.cease is CR 608.2n's own mechanism
    -- for the three ability kinds and reaches the same end state one step
    -- earlier.
    Just (Source.OfAbility _) -> cease
    Just (Source.OfTrigger _) -> cease
    Just (Source.OfInherentTrigger _) -> cease
    -- CR 701.42a puts a melded permanent onto the battlefield, CR 730.2 leaves a
    -- merged one there, and CR 114.1 keeps an emblem in the command zone, so none
    -- of the three is ever on the stack for rule 724.1b to reach.
    Just (Source.OfMeld _) -> cease
    Just (Source.OfMerge _) -> cease
    Just (Source.OfEmblem _) -> cease
    Nothing -> cease

-- CR 707.10: what a copy of this object's Source would be, and which of CR
-- 707.10's nouns the copy is, or Nothing when the object is neither a spell nor
-- an ability. A CLASSIFICATION -- read off the same Source that Game.isSpell and
-- Game.isAbility read -- never which card it is.
--
-- A copy of a SPELL gets a Source of its own (CR 112.1a's spell with no card),
-- while a copy of an ABILITY keeps the original's Source unchanged: CR 707.10b's
-- "a copy of an ability has the same source as the original ability", which that
-- payload already carries (the source object and the ability itself). So the
-- rule's second sentence -- an ability referring to its source by name refers to
-- that same object -- and its third -- the copy counts as the same ability for
-- effects counting resolutions -- both hold by construction rather than by
-- anything written here: the OfAbility arm below answers with the very
-- ActivatedAbilitySource it was handed, which is the key
-- Parun.Engine.Resolve.recordAbilityResolution files a resolution under.
-- Parun.CopySpec's Longtusk Cub case proves the second and its Ashling the
-- Pilgrim case the third.
--
-- A copy of a copy answers with the copy's own printing: CR 707.2's copiable
-- values are the ones the copied object reports, and its snapshot already carries
-- them.
copyOnStackOf :: Source.Source -> Maybe (Source.Source, StackObjectKind.StackObjectKind)
copyOnStackOf source = case source of
  Source.OfCard pid -> Just (Source.OfSpellCopy pid, StackObjectKind.Spell)
  Source.OfSpellCopy pid -> Just (Source.OfSpellCopy pid, StackObjectKind.Spell)
  -- CR 722.3c's copy is a spell once cast, so copying it is CR 707.10's ordinary
  -- case and the result is a copy of a SPELL -- the arm above's answer, off this
  -- copy's own printing (CR 707.2's copiable values). That is also CR 722.3d's
  -- "if a prepare spell is copied, the copy is also a prepare spell", in the only
  -- reading parun can observe; Parun.PreparationSpec's "CR 722.3d Twincast copies
  -- the cast Jump and the copy is a Jump of its own" is what proves it.
  Source.OfCardCopy pid -> Just (Source.OfSpellCopy pid, StackObjectKind.Spell)
  Source.OfAbility a -> Just (Source.OfAbility a, StackObjectKind.ActivatedAbility)
  Source.OfTrigger t -> Just (Source.OfTrigger t, StackObjectKind.TriggeredAbility)
  -- CR 725.2's sourceless triggered ability is a triggered ability all the same,
  -- and Parun.Engine.Target.abilityRecipients offers it, so it copies like one.
  Source.OfInherentTrigger t -> Just (Source.OfInherentTrigger t, StackObjectKind.TriggeredAbility)
  -- CR 707.10 copies what is ON THE STACK, and none of these three ever is: a
  -- melded permanent and a token are put onto the battlefield (CR 701.42a, CR
  -- 111.1) and an emblem into the command zone (CR 114.1). CR 202.3c's copy of a
  -- melded permanent is a permanent copy and does not come through here.
  Source.OfMeld _ -> Nothing
  Source.OfMerge _ -> Nothing
  Source.OfToken _ -> Nothing
  Source.OfEmblem _ -> Nothing

-- The TARGETS a spell or ability on the stack currently has, per slot. Every
-- recipient-valued binding restricted to the slots the object actually declares
-- a target in: Binding.targetsOf reports the reserved ones too -- CR 109.5's
-- `you` above all -- and CR 115.10b says outright that "you" indicates no
-- target. Restricted for legalSlot's own reason as well: a slot declaring no
-- target was never targeted, so CR 608.2b has nothing to re-check there.
--
-- Read off the LIVE bindings rather than off what an announcement chose, which
-- is what makes it answer for a copy whose targets CR 707.10c has just changed.
targetsOnStack :: ObjectId -> GameState -> Map.Map SlotName (Set Recipient)
targetsOnStack oid gs =
  Maybe.fromMaybe Map.empty $ do
    obj <- Game.lookupObject oid gs
    pure (Map.restrictKeys (Binding.targetsOf (Object.bindings obj)) (Map.keysSet (stackTargetSlots obj oid gs)))

-- CR 601.2c: the target slots an object on the stack declares, for whichever of
-- CR 707.10's three nouns it is. A CLASSIFICATION off the object's Source, like
-- copyOnStackOf above and never which card it is.
--
-- A card-backed object reads its face (targetSlotsOf over Projection.spellFaceOf,
-- whose spell text is the copiable one, CR 707.2). An ability has no
-- card behind it -- CR 113.7a makes it an object in its own right, and
-- Game.cardOf answers Nothing for one -- so its slots come off the modal its
-- Source carries, which is where Parun.Engine.Activate announced them against and
-- where Parun.Engine.Stack's two ability arms read its modes at resolution.
--
-- CR 612.1's rewrite (Projection.rewriteTargetSlot) is applied on the card-backed
-- half alone, and that is agreement rather than an omission this reader makes:
-- the two roads an ability's slots already travel -- Parun.Engine.Activate's
-- announcement and Parun.Engine.Stack's resolution -- read the modal unrewritten,
-- so a rewrite here would describe a slot neither of them announced. Whenever CR
-- 612 does have to reach an ability on the stack, all three move together.
stackTargetSlots :: Object.Object -> ObjectId -> GameState -> Map.Map SlotName TargetSlot.TargetSlot
stackTargetSlots obj oid gs =
  let chosen = Binding.modesOf (Object.bindings obj)
      fromFace = maybe Map.empty (targetSlotsOf obj oid gs) (Projection.spellFaceOf oid gs)
      -- CR 603.2's player slots baked in, off the object's OWN bindings -- the
      -- map Parun.Engine.Engine.placeBorne baked with as the ability went on the
      -- stack, and which CR 707.10 copied onto a copy verbatim. Not optional:
      -- Filter.HeldByBound answers False wherever `matches` reaches it
      -- with no slotPlayers entry, so an unbaked slot admits nobody, and CR 707.10c's prompt would then be
      -- elided as "settled" while the copy silently kept the original's target
      -- (Questing Beast's "that player" under Lithoform Engine).
      baked = Target.bakeModal (Binding.playerSlots (Object.bindings obj))
      -- The per-player copies the announcement bound, as CR 608.2b reads them. A
      -- REGRESSION FENCE: no test copies or re-targets a per-player ability.
      copies = Target.boundCopies (Map.keysSet (Object.bindings obj))
   in case Object.source obj of
        Source.OfAbility a -> copies (Modal.modesTargetSlots chosen (baked (ActivatedAbility.modal (ActivatedAbilitySource.ability a))))
        Source.OfTrigger t -> copies (Modal.modesTargetSlots chosen (baked (TriggeredAbility.modal (TriggeredAbilitySource.ability t))))
        Source.OfInherentTrigger t -> copies (Modal.modesTargetSlots chosen (baked (TriggeredAbility.modal (InherentTriggerSource.ability t))))
        Source.OfCard _ -> fromFace
        Source.OfSpellCopy _ -> fromFace
        Source.OfCardCopy _ -> fromFace
        Source.OfMeld _ -> fromFace
        Source.OfMerge _ -> fromFace
        Source.OfToken _ -> fromFace
        Source.OfEmblem _ -> fromFace

-- CR 707.10d and CR 707.10e's shared test, and the whole of what either rule
-- leaves to arithmetic: for each candidate, the target maps the copy would carry
-- if EVERY instance of the word "target" named that candidate. A candidate that
-- cannot fill them all is dropped, which is rule 707.10d's last sentence -- "if
-- that player or object isn't a legal target for each instance of the word
-- 'target', a copy isn't created for that player or object" -- and rule
-- 707.10e's "the copy isn't created", the same test with one candidate.
--
-- A slot the original filled with TWO targets keeps nobody, and that is the
-- rule rather than a shortcut: every one of the copy's targets must be the same
-- object, and one object cannot fill two instances of "target" in one slot.
--
-- Legality is measured against the ORIGINAL -- the copy does not exist yet --
-- and from `perspective`'s seat, which each caller names. Rule 707.10c's own
-- derivation, with the same seed: the slots being written are dropped from the
-- environment, so a sibling read is not answered off the target it is about to
-- replace.
--
-- A candidate is a player or an object (CR 115.1), matched against the offered
-- recipients by referent, since the pool that offers a permanent tags it
-- (Recipient.ToCreature) where the ref that named it did not.
--
-- An original that has left the stack is read as it last existed (CR 608.2h),
-- through lastKnownOriginal below.
copyRetargets :: PlayerId -> ObjectId -> GameState -> [Recipient] -> [(Recipient, Map.Map SlotName (Set Recipient))]
copyRetargets perspective original live candidates = Maybe.fromMaybe [] $ do
  let gs = lastKnownOriginal original live
  obj <- Game.lookupObject original gs
  let slots = stackTargetSlots obj original gs
      current = targetsOnStack original gs
      seed = Map.withoutKeys (Object.bindings obj) (Map.keysSet slots)
      fresh = Target.legalSets (resolvingKind original gs) (resolvingAbilityName original gs) (Just perspective) False seed original slots gs
      takes candidate slot = Set.filter (Recipient.sameReferent candidate) (Map.findWithDefault Set.empty slot fresh)
      pick candidate =
        let chosen = Map.mapWithKey (\slot _ -> takes candidate slot) current
         in if not (Map.null current)
              && and (Map.elems (Map.map ((== 1) . Set.size) current))
              && and (Map.elems (Map.map ((== 1) . Set.size) chosen))
              && Target.jointlyCoherent (resolvingKind original gs) (resolvingAbilityName original gs) (Just perspective) seed original slots chosen gs
              then Just (candidate, chosen)
              else Nothing
  pure (Maybe.mapMaybe pick candidates)

-- CR 608.2h: the board with a copy's ORIGINAL as it last existed. A spell that
-- has left the stack is put back into the object map off GameState.stackArchive,
-- in no zone's list, so every live reader of its face, slots, targets and
-- controller answers its last known information while nothing else on the board
-- can see it. A live original answers the board unchanged. Parun.CopySpec's "CR
-- 608.2h the copy is made even when the Growth was countered first" (Ivy,
-- Gleeful Spellthief) and "CR 608.2h Zada still copies a Growth countered while
-- the trigger waited" prove the stated and the for-each roads.
lastKnownOriginal :: ObjectId -> GameState -> GameState
lastKnownOriginal original gs = case (Game.lookupObject original gs, Map.lookup original (GameState.stackArchive gs)) of
  (Nothing, Just obj) -> gs {GameState.objects = Map.insert original obj (GameState.objects gs)}
  _ -> gs

-- CR 707.10e: ONE copy, every one of whose targets is the player or object the
-- effect names. Answers the empty list where "the copy isn't created", so the
-- copy does not exist rather than existing and being countered for an illegal
-- target (CR 608.2b).
--
-- A PLAYER named here is a regression fence rather than a proven line: Zevlor,
-- Elturel Exile is its producer (#4563), and Ivy, Gleeful Spellthief names an
-- object.
--
-- A ref naming anything but exactly ONE object also answers the empty list: rule
-- 707.10e specifies "a new target", singular, so a ref that swept several has
-- not said which, and a ref that named none has said nothing. Ivy, Gleeful
-- Spellthief's ref is the effect's own source, so a departed source is what
-- reaches the second case.
--
-- No prompt of any kind: rule 707.10d's order is a choice among several copies,
-- and there is only ever one here.
--
-- TWO SEATS: the ref is the effect's text, read from `controller`, and rule
-- 707.10e's "legal target" is the copy's, judged from `copier`, its controller.
-- A REGRESSION FENCE: Ivy's copier is the effect's controller.
copyStatedTargets :: PlayerId -> PlayerId -> ObjectId -> ObjectId -> Map.Map SlotName (Set Recipient) -> ObjectId -> ObjectRef -> Game [Map.Map SlotName (Set Recipient)]
copyStatedTargets controller copier resolving source legal original newRef = do
  gs <- State.get
  pure $ case objectRefRecipients legal resolving controller source gs newRef of
    [new] -> fmap snd (copyRetargets copier original gs [new])
    _ -> []

-- The objects an Effect.CopyStackObject names: objectRefObjects' live answer,
-- plus CR 608.2h's last known information for the ABILITY'S OWN SOURCE where the
-- ref names it and it has left the stack. CR 702.40a's storm over a Grapeshot
-- countered while its trigger waited is the board, and CR 113.7a is why the
-- trigger still copies anything -- it "exists on the stack independently of its
-- source".
--
-- The SOURCE alone is added here: every other object this opcode can name is a
-- TARGET, which CR 608.2b re-checks and blanks, a slot the triggering event
-- bound (Ivy, Gleeful Spellthief's "that spell"), which objectRefObjects already
-- answers once the spell has left, or a sweep, which names what is on the stack
-- NOW. So the two stack sweeps keep answering live for every other opcode.
--
-- The ref's own Filter decides, read off the last known view, so a ref naming
-- anything but the source (Swift Silence's `Not IsSource`) still names nothing.
-- EachSpell needs no CR 112.1 narrowing of its own, nor EachAbility an arm: the
-- one id asked of GameState.stackArchive is the effect's own source, which is
-- never an ability (CR 113.7), though Parun.Engine.Game.cease files abilities
-- there too.
copyStackSubjects :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> GameState -> ObjectRef -> [ObjectId]
copyStackSubjects legal resolving controller source gs ref =
  let live = objectRefObjects legal resolving controller source gs ref
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      named filter_ =
        if Map.member source (GameState.stackArchive gs) && Maybe.maybe False (\view -> Filter.matches context view filter_) (Projection.viewWithLastKnownAnywhere gs source)
          then [source]
          else []
      stated = case ref of
        ObjectRef.EachOnStack filter_ -> named filter_
        ObjectRef.EachSpell filter_ -> named filter_
        _ -> []
   in if source `elem` live then live else stated <> live

-- CR 707.10d: the copies' targets, one map per candidate, in the order their
-- controller chose. Answers the empty list where nothing is copied at all.
--
-- The candidates are the card's own description, every ref's players and
-- objects together (Radiate's "each other permanent or player"), narrowed by the
-- rule's "could target" -- copyRetargets above, whose test rule 707.10e shares.
--
-- Less what the original already targets, which is the printed "OTHER": every
-- hit for Scryfall o:"could target" (2026-10-01) that copies per candidate reads
-- "for each other ...", and each gates on an original with a single target, so
-- "other" is that target. A printing without the "other" would refute this.
-- Precursor Golem's "each other Golem" is where that target is not the source.
--
-- The ORDER is the whole of what CR 707.10d leaves to a player, and
-- Prompt.OrderForEach is the question; the rule states no primary key, so the
-- one prompt covers the whole list rather than forEachOrder's APNAP groups.
-- Elided for fewer than two, which is one order.
--
-- THREE SEATS. `controller` reads the effect's own text ("each other creature
-- YOU control" is Zada's controller). `copier` controls the copies (CR 707.10),
-- so orders them: Precursor Golem's ruling, "That player chooses the order". And
-- "could target" is the ORIGINAL's, judged from ITS controller (CR 109.5):
-- Ink-Treader Nephilim's ruling has a copy aimed where only the caster's "an
-- opponent" reached, and countered for it on resolution (CR 608.2b).
-- Parun.CopySpec's Precursor Golem and Radiate groups prove all three.
copyForEachTargets :: PlayerId -> PlayerId -> ObjectId -> ObjectId -> Map.Map SlotName (Set Recipient) -> ObjectId -> NonEmpty.NonEmpty ObjectRef -> Game [Map.Map SlotName (Set Recipient)]
copyForEachTargets controller copier resolving source legal original candidateRefs = do
  live <- State.get
  let gs = lastKnownOriginal original live
      caster = fmap (\obj -> Maybe.fromMaybe (Projection.defaultControllerOf obj) (Projection.controllerOf original gs)) (Game.lookupObject original gs)
      targeted = Foldable.fold (targetsOnStack original gs)
      other candidate = not (any (Recipient.sameReferent candidate) targeted)
      candidates = ListUtils.nubOrd (concatMap (filter other . objectRefRecipients legal resolving controller source live) candidateRefs)
      picks = foldMap (\seat -> copyRetargets seat original gs candidates) caster
  ordered <- case picks of
    _ : _ : _ -> do
      answer <- Game.choose (Prompt.OrderForEach (Decide.deciderFor copier live) copier resolving (fmap fst picks))
      pure (Game.permute picks answer)
    _ -> pure picks
  pure (fmap snd ordered)

-- CR 707.10c: "the player may leave any number of the targets unchanged, even if
-- those targets would be illegal. If the player chooses to change some or all of
-- the targets, the new targets must be legal." CR 115.7d says the same of an
-- original spell or ability, which Effect.ChooseNewTargets re-aims.
--
-- TWO SEATS: `chooser` is asked and draws any CR 406.4 pile, and `controller`
-- -- the object's own -- is CR 109.5's "you" that legality is judged from, since
-- the targets stay the object's. They differ only under Effect.ChooseNewTargets,
-- whose resolving controller chooses for an object someone else may control.
-- Parun.TargetSpec's Redirect group proves both seats.
--
-- ONE prompt, not a "may" followed by a choice: leaving every target where it is
-- is an answer to the same question, so a second prompt would ask nothing the
-- first cannot say. Prompt.ChooseTargets is the shape -- per slot, how many
-- targets and which recipients -- and this is the second place it is raised;
-- Parun.Engine.Target.chooseTargets raises it for CR 601.2c's announcement.
--
-- The OFFERED set per slot is the recipients legal on the board NOW, unioned
-- with what the copy already targets, which is the rule's two halves: a changed
-- target must be legal, an unchanged one need not be. The count is what the
-- original announced, CR 707.10 having copied the decision and CR 707.10c
-- offering no chance to change it -- or, for a spell that announced nothing
-- (`unannounced`), the count its text fixes.
--
-- Legal is judged from `controller`, the object's own; a changed target must
-- also lie in the range of `chooser`, asked for an effect of `source` (CR
-- 801.5a, Target.inChooserRange) -- Redirect's caster choosing for another
-- player's spell.
--
-- Not raised when no slot can be answered any other way -- the offered set is
-- exactly what is already chosen -- because then the options are
-- indistinguishable.
--
-- Reject-not-repair, as every other announcement is: an answer that names a slot
-- it was not offered, the wrong number of targets, or a recipient outside the
-- offered set leaves the copied targets standing rather than being patched into
-- something the player did not choose.
--
-- CR 601.2c's joint check reaches this answer as it reaches a cast's: the offer
-- above is the UNION over what a sibling slot could take, so two slots that
-- exclude each other pass `wellFormed` and Target.jointlyCoherent is what judges
-- them together. Asked on the DRAWN answer rather than the raw one, so what the
-- re-derivation reads is the card CR 406.4 picked out of a pile -- the order
-- Parun.Engine.Cast.castProposed takes, chooseTargets drawing before it asks.
--
-- CR 733.1 is what a rejection falls to, and it is a REVERSAL rather than a
-- remedy of its own: the choice is undone, and the copy is left holding the
-- targets CR 707.10 already gave it. Not rule 707.10c's "may leave any number of
-- the targets unchanged", which is the player's option and not the rules'
-- handling of an illegal one -- the two coincide here only because undoing this
-- particular choice restores exactly that state. CR 733.2's redo has no analogue
-- inside a resolution: nobody holds priority, and a pure prompt-to-answer
-- decider re-asked would loop on a stubborn answer.
chooseNewTargetsFor :: Bool -> ObjectId -> PlayerId -> PlayerId -> ObjectId -> Game ()
chooseNewTargetsFor unannounced source chooser controller copyId = do
  gs <- State.get
  Monad.forM_ (Game.lookupObject copyId gs) $ \copy -> do
    let slots = stackTargetSlots copy copyId gs
        -- TARGET slots only, which targetsOnStack is: the reserved slots are
        -- not targets and are not CR 707.10c's to change.
        current = targetsOnStack copyId gs
        -- `unannounced`: the object became a copy of a card and so announced
        -- nothing (CR 707.2, "it stops having any targets"). Each slot whose
        -- text fixes its count is offered that many (Target.fixedCount), and
        -- leaving it empty is leaving it unchanged. Never for a copy CR 707.10
        -- made, whose empty slot is a count its original announced.
        blank = if unannounced then Map.withoutKeys (Map.mapMaybe Target.fixedCount slots) (Map.keysSet current) else Map.empty
        -- CR 608.2b's own derivation, made against the CURRENT board: this is
        -- a fresh choice of targets rather than a re-check of the old one, so
        -- it reads what the board can supply now.
        --
        -- Seeded with the copy's own bindings, which is where CR 707.10 put the
        -- original's decisions: a slot's CR 202.3 computed bound reading the
        -- announced X (Stir the Grave) is answered off the SAME number the
        -- original was, because CR 707.10c changes targets and nothing else.
        --
        -- A REGRESSION FENCE rather than a proven line, and the honest reason is
        -- that the announced X reaches the bound a second way: Quantity.InSlot
        -- asks the object the evaluation names before it asks the context, and
        -- for a copy that object IS the announcement's holder. So the behaviour
        -- Parun.CopySpec's stirCopySpec proves stands with this seed empty too,
        -- and what the seed adds is every OTHER slot atom -- Filter's
        -- Shares Name Bound and IsBound, a ZoneScope.InSlot pool -- reading a
        -- binding of the copy's that is not one of the re-chosen slots. Nothing
        -- drives that half: stirCopySpec is the only case that copies a spell
        -- whose slot reads the announcement at all, and its slot reads the X.
        --
        -- The slots being re-chosen are dropped from it. They are not decisions
        -- the copy keeps -- this call is choosing them -- so a sibling read must
        -- not be answered off the target it is about to replace, and CR 601.2c's
        -- own road seeds no target either (Parun.Engine.Cast.castProposed). The
        -- second pass below is what relates one re-chosen slot to another.
        seed = Map.withoutKeys (Object.bindings copy) (Map.keysSet slots)
        -- CR 113.7: what the slots are judged against is the ability's SOURCE
        -- -- the object CR 113.7a's source reads (power, owner, CR 607.2d's
        -- chosen colour) are asked of -- and a copied ability keeps its
        -- original's source (Game.abilitySourceOf). A spell copy is its own
        -- source. Parun.TargetSpec's "a Lithoform Engine copy of the Paladin's
        -- ability" is the proof.
        aimer = Maybe.fromMaybe copyId (Game.abilitySourceOf copyId gs)
        fresh = Target.legalSets (resolvingKind copyId gs) (resolvingAbilityName copyId gs) (Just controller) False seed aimer slots gs
        -- CR 406.4: what this player may not name specifically is offered as
        -- the pile it sits in, exactly as at CR 601.2c. The targets already
        -- CHOSEN are offered unchanged whatever they are, rule 707.10c letting
        -- one stand even when it is now illegal.
        piled slot n = Target.piledOffer (Just n) (Just chooser) gs (Target.inChooserRange source chooser gs (Map.findWithDefault Set.empty slot fresh))
        offer slot (n, recipients) = (n, Set.union recipients (piled slot n))
        asked = Map.mapWithKey offer (Map.union (fmap (\recipients -> (Natural.length recipients, recipients)) current) (fmap (\n -> (n, Set.empty)) blank))
        held = Map.union current (Set.empty <$ blank)
        -- Every slot answerable only one way means the options are
        -- indistinguishable, and CR 707.10c's offer is elided.
        settled slot = Set.isSubsetOf (piled slot (maybe 0 fst (Map.lookup slot asked)))
    Monad.unless (and (Map.elems (Map.mapWithKey settled held))) $ do
      answer <- Game.choose (Prompt.ChooseTargets (Decide.deciderFor chooser gs) chooser copyId asked)
      let admits slot (n, offered) picked = picked == Map.findWithDefault Set.empty slot current || (Natural.length picked == n && Set.isSubsetOf picked offered)
          wellFormed =
            Map.keysSet answer == Map.keysSet asked
              && and (Map.elems (Map.intersectionWith id (Map.mapWithKey admits asked) answer))
      Monad.when wellFormed $ do
        -- CR 406.4's draw, run on the ANSWER: a pile the player named becomes
        -- the card randomness picked out of it before any target is recorded.
        -- Not implemented: revealing the card it picked (#5424).
        drawn <- traverse (fmap fst . Target.drawFromPiles (Just chooser)) answer
        -- CR 707.10c: "if the player chooses to change some or all of the
        -- targets, the new targets must be legal". Asked of the DRAWN answer
        -- and not of the raw one, because rule 406.4 draws from the whole pile
        -- -- the card it names can be one this slot refuses, and a pile is
        -- never a target that was left unchanged. An unchanged target is
        -- admitted whatever it is, which is the rule's own first sentence.
        --
        -- Parun.ExileSpec's "CR 707.10c a copy whose re-choice draws a card it
        -- refuses keeps its old target, so both spells resolve" proves this
        -- line: without it the copy records the illegal card and CR 608.2b
        -- counters it, where the rule leaves it resolving on its old target.
        --
        -- CR 115.7d's joint half: the new targets "must not cause any unchanged
        -- targets to become illegal". So the joint check refuses only what was
        -- NOT already refused under the object's current targets -- an unchanged
        -- target already illegal stands, one legal before must stay legal.
        -- Parun.TargetSpec's Bioshift cases prove both halves.
        let stands slot picked = Set.isSubsetOf picked (Set.union (Map.findWithDefault Set.empty slot current) (Map.findWithDefault Set.empty slot fresh))
            already = Target.jointlyIllegal (resolvingKind copyId gs) (resolvingAbilityName copyId gs) (Just controller) seed aimer slots current gs
            caused slot refused = not (Set.isSubsetOf refused (Map.findWithDefault Set.empty slot already))
            coherent = not (or (Map.mapWithKey caused (Target.jointlyIllegal (resolvingKind copyId gs) (resolvingAbilityName copyId gs) (Just controller) seed aimer slots drawn gs)))
        Monad.when (and (Map.elems (Map.mapWithKey stands drawn)) && coherent) $ do
          rebound <- reaimDivisions chooser copyId (Object.bindings copy) (Map.filter (not . Set.null) drawn)
          Monad.forM_ rebound $ \bindings -> do
            let write o = o {Object.bindings = Map.union bindings (Object.bindings o)}
            State.modify' (\g -> g {GameState.objects = Map.adjust write copyId (GameState.objects g)})

-- Effect.ChooseNewTargets' and Effect.ChangeTargets' shared walk: over each
-- named spell or ability still on the stack, the re-aim is asked of the
-- resolving controller (Redirect's and Deflection's "you") and judged from the
-- object's own controller, which is the re-aim's second argument.
retargetEach :: (PlayerId -> ObjectId -> Game ()) -> Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> ObjectRef -> Game ()
retargetEach reaim legal resolving controller source ref = do
  gs <- State.get
  Monad.forM_ (objectRefObjects legal resolving controller source gs ref) $ \oid -> do
    g <- State.get
    Monad.forM_ (List.find ((== Zone.Stack) . Object.zone) (Game.lookupObject oid g)) $ \obj ->
      Monad.forM_ (copyOnStackOf (Object.source obj)) $ \(_, kind) -> do
        let aimer = Maybe.fromMaybe (Projection.defaultControllerOf obj) (Projection.controllerOf oid g)
            before = targetsOnStack oid g
        reaim aimer oid
        -- A recipient CR 115.7 newly chose becomes a target of the object (CR
        -- 601.2c's event), so CR 702.21a's ward fires on it. Only what CHANGED,
        -- per slot: unlike the copy arm, the object already held the targets it
        -- kept. Parun.TargetSpec's Redirect group proves it.
        after <- State.get
        let changed = Map.differenceWith (\new old -> let fresh = Set.difference new old in if Set.null fresh then Nothing else Just fresh) (targetsOnStack oid after) before
        Monad.unless (Map.null changed) (Event.becameTarget after oid kind aimer changed)

-- CR 115.7a: "each target can be changed only to another legal target", a
-- target that can't be "is unchanged, even if the original target is itself
-- illegal by then", and "if all the targets aren't changed to other legal
-- targets, none of them are changed". Effect.ChangeTargets' re-aim, with
-- chooseNewTargetsFor's two seats and range cut: `chooser` is asked,
-- `controller` -- the object's own -- is who legality is judged from.
--
-- Per slot, the OFFER is the recipients legal now less what that slot already
-- targets ("another"), and the count is what the slot holds. A slot offering
-- fewer leaves every target unchanged, unasked -- a REGRESSION FENCE, since the
-- rejection below would refuse every answer anyway. No "may": unlike CR 115.7d
-- the current targets are not offered, so leaving them is no answer. Not raised
-- when every slot's offer is exactly its count, the options being
-- indistinguishable.
--
-- Not implemented: a multi-target slot reusing one of its own current targets
-- for another of them, which CR 115.7e allows (#4659).
--
-- Reject-not-repair, chooseNewTargetsFor's posture and for its reason: an
-- answer outside the offer, a CR 406.4 draw landing on a refused or current
-- target, or a final set CR 601.2c's joint check refuses (CR 115.7e judges only
-- the final set) leaves every target unchanged. Parun.ExileSpec's "CR 115.7a a
-- change of target that draws a card the spell refuses leaves the old target,
-- so the spell resolves" proves the refused draw.
changeTargetsFor :: ObjectId -> PlayerId -> PlayerId -> ObjectId -> Game ()
changeTargetsFor source chooser controller oid = do
  gs <- State.get
  Monad.forM_ (Game.lookupObject oid gs) $ \obj -> do
    let slots = stackTargetSlots obj oid gs
        current = Map.filter (not . Set.null) (targetsOnStack oid gs)
        seed = Map.withoutKeys (Object.bindings obj) (Map.keysSet slots)
        aimer = Maybe.fromMaybe oid (Game.abilitySourceOf oid gs)
        fresh = Target.legalSets (resolvingKind oid gs) (resolvingAbilityName oid gs) (Just controller) False seed aimer slots gs
        another old = Set.filter (\r -> not (any (Recipient.sameReferent r) old))
        -- CR 406.4's draws capped at the slot's count, chooseNewTargetsFor's
        -- cap. A REGRESSION FENCE: no test drives a pile through this road.
        offer slot old = (Natural.length old, Target.piledOffer (Just (Natural.length old)) (Just chooser) gs (Target.inChooserRange source chooser gs (another old (Map.findWithDefault Set.empty slot fresh))))
        asked = Map.mapWithKey offer current
        enough (n, offered) = Natural.length offered >= n
        settled (n, offered) = Natural.length offered == n
    Monad.when (not (Map.null asked) && all enough asked) $ do
      answer <-
        if all settled asked
          then pure (fmap snd asked)
          else Game.choose (Prompt.ChooseTargets (Decide.deciderFor chooser gs) chooser oid asked)
      let admits (n, offered) picked = Natural.length picked == n && Set.isSubsetOf picked offered
          wellFormed =
            Map.keysSet answer == Map.keysSet asked
              && and (Map.elems (Map.intersectionWith admits asked answer))
      Monad.when wellFormed $ do
        -- Not implemented: revealing the card CR 406.4's draw picked (#5424).
        drawn <- traverse (fmap fst . Target.drawFromPiles (Just chooser)) answer
        let stands slot picked =
              Set.isSubsetOf picked (Map.findWithDefault Set.empty slot fresh)
                && another (Map.findWithDefault Set.empty slot current) picked == picked
            coherent = all Set.null (Target.jointlyIllegal (resolvingKind oid gs) (resolvingAbilityName oid gs) (Just controller) seed aimer slots drawn gs)
        Monad.when (and (Map.elems (Map.mapWithKey stands drawn)) && coherent) $ do
          rebound <- reaimDivisions chooser oid (Object.bindings obj) drawn
          Monad.forM_ rebound $ \bindings -> do
            let write o = o {Object.bindings = Map.union bindings (Object.bindings o)}
            State.modify' (\g -> g {GameState.objects = Map.adjust write oid (GameState.objects g)})

-- CR 115.7f: each re-aimed slot's new binding, "the original division can't be
-- changed": a target left standing keeps its part, and the parts of the
-- replaced targets go to the new ones -- each the same where they are equal, and
-- otherwise as the chooser hands them out (Prompt.ChooseDivision's Parts). An
-- answer that does not hand out exactly those parts reverses the whole re-aim,
-- chooseNewTargetsFor's reject-not-repair. An undivided slot binds its targets
-- alone. docs/decisions.md, "Who says which new target takes a replaced
-- target's part of a division".
reaimDivisions :: PlayerId -> ObjectId -> Map.Map SlotName Binding.Type.Binding -> Map.Map SlotName (Set Recipient) -> Game (Maybe (Map.Map SlotName Binding.Type.Binding))
reaimDivisions chooser oid bindings picked =
  fmap sequence . flip Map.traverseWithKey picked $ \slot new ->
    case Binding.Type.division =<< Map.lookup slot bindings of
      Nothing -> pure (Just (Binding.toRecipients new))
      Just division -> do
        let kept = Map.restrictKeys division new
            dividedAs parts = Just ((Binding.toRecipients new) {Binding.Type.division = Just (Map.union kept parts)})
        case (NonEmpty.nonEmpty (List.sort (Map.elems (Map.withoutKeys division new))), NonEmpty.nonEmpty (Set.toList (Set.difference new (Map.keysSet division)))) of
          (Just parts, Just added)
            | any (/= NonEmpty.head parts) parts -> do
                gs <- State.get
                let dividing = Dividing.Parts parts
                answer <- Game.choose (Prompt.ChooseDivision (Decide.deciderFor chooser gs) chooser oid dividing added)
                pure (if Target.divides dividing added answer then dividedAs answer else Nothing)
            | otherwise -> pure (dividedAs (Map.fromList (fmap (\r -> (r, NonEmpty.head parts)) (NonEmpty.toList added))))
          _ -> pure (dividedAs Map.empty)

-- CR 707.2: a spell on the stack that becomes a copy acquires the original's
-- "choices made when casting or activating it (mode, targets, the value of X,
-- whether it was kicked ...)", replacing its own -- and has none when the
-- original is not on the stack, as Transcantation's ruling reads it ("it stops
-- having any targets"), which Parun.CopySpec's Transcantation cases prove.
-- CopyStackObject's arm carries the same decisions by copying the
-- whole object (CR 707.10); here the object stays, so the decisions are named:
-- every binding but the reserved ones that are the subject's own (its
-- controller, itself, its copy stamp), and the cast records rule 707.2 lists.
-- With no original on the stack it is Object.unannounced, which CR 608.2b's
-- Resolve.targetsAllIllegal reads.
-- Parun.CopySpec's "CR 707.2 a spell that becomes a copy of a Bolt" proves it.
acquireChoices :: Modal.Type.Modal Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Acquisition.Acquisition -> Maybe Object.Object -> Object.Object -> Object.Object
acquireChoices copiedSpell acquisition mOriginal subject =
  let own = Set.fromList [Binding.you, Binding.triggerSource, Binding.copySource, Binding.ownCopySource, Binding.turnedMergeSource, Binding.shownMergeSource]
      -- CR 700.2: a spell that is not modal has no mode to choose, so the copy
      -- of one from off the stack still resolves its text: the one selection
      -- the copied text forces (Modal.forcedSelection), where there is one.
      forced = Modal.forcedSelection (Set.fromList (fmap ModeIndex.MkModeIndex (take (Seq.length (Modal.Type.modes copiedSpell)) [0 ..]))) (Modal.Type.selection copiedSpell)
      decisions = maybe (maybe Map.empty (Binding.fromChoices Map.empty Nothing) forced) (\o -> Map.withoutKeys (Object.bindings o) own) mOriginal
   in subject
        { Object.bindings = Map.union (Map.restrictKeys (Object.bindings subject) own) decisions,
          Object.announcedX = mOriginal >>= Object.announcedX,
          Object.paidCosts = maybe Map.empty Object.paidCosts mOriginal,
          -- The opponents its gift costs were promised to, the paid costs' own
          -- record (CR 702.174a): the original's, noted for the abilities the
          -- subject now has (`acquisition`, CR 607.5), since rule 707.2 hands
          -- them on with the text that reads them.
          Object.chosenPlayers = maybe Map.empty (\o -> Map.filter (not . Map.null) (Map.singleton acquisition (Map.findWithDefault Map.empty (Object.acquisition o) (Object.chosenPlayers o)))) mOriginal,
          Object.boughtBack = any Object.boughtBack mOriginal,
          Object.unannounced = Maybe.isNothing mOriginal,
          Object.castUsing = mOriginal >>= Object.castUsing
        }

-- CR 702.34a / 702.127a / 702.133a / 702.180a: the exile-as-it-leaves-the-stack
-- ability is the SPELL's own static ability, conditioned on its cast record, so
-- a spell that became a copy (CR 707.2) answers with the copied keywords and the
-- acquired record rather than the ones Parun.Engine.Cast armed at cast. Aftermath
-- asks where the spell was cast from, which is the subject's own history rather
-- than a copiable choice. Parun.CopySpec's "CR 707.2 a flashed-back spell that
-- becomes a copy of a Bolt" proves the disarm.
rearmStackExile :: ObjectId -> PC.ProjectedCharacteristics -> Object.Object -> GameState -> GameState
rearmStackExile subject copied obj gs =
  let armed r = ActiveReplacement.source r == subject && ActiveReplacement.effect r == Keyword.castFromGraveyardExile
      keywords = Map.keysSet (PC.keywords copied)
      eligible = if Object.castFrom obj == Just Zone.Graveyard then keywords else Set.delete Keyword.Type.Aftermath keywords
   in Cast.installCastFromGraveyard (Projection.defaultControllerOf obj) eligible (Object.castUsing obj) subject gs {GameState.replacements = filter (not . armed) (GameState.replacements gs)}

-- CR 702.128b: the marks a token has from being created by this resolving
-- object, read off the keyword that minted it (ActivatedAbility.keyword).
resolvingMarks :: ObjectId -> GameState -> Set.Set Designation.Designation
resolvingMarks resolving gs = case thisAbilitySource resolving gs of
  Just (Source.OfAbility minted) -> foldMap Keyword.createdMarks (ActivatedAbility.keyword (ActivatedAbilitySource.ability minted))
  _ -> Set.empty

-- The carrier CR 707.9a's "this ability" points at: the RESOLVING object's own
-- Parun.Types.Source, since rule 602.2a and rule 603.3 both put the ability's text
-- on the stack object, so the words point at a value already in hand rather than
-- at a source that may have left (CR 113.7a).
--
-- The Source itself, unclassified: which of CR 113.3's arms carries an ability,
-- and which list it joins, is Projection.View.applyCopyException's to say, and it
-- says it by casing on the arm rather than on the ability.
thisAbilitySource :: ObjectId -> GameState -> Maybe Source.Source
thisAbilitySource resolving gs = fmap Object.source (Game.lookupObject resolving gs)

-- The name a conjure's candidate answers to, which is what Prompt.RandomCard
-- and Prompt.ChooseConjuredCard offer and what their answer is matched back
-- against. The FRONT face's (CR 712.8a): no printed spellbook holds a card with
-- a second face, and a conjure that named one outright would still be picked out
-- of a one-candidate list, which raises no prompt.
conjuredName :: Card.Type.Card -> CardName.CardName
conjuredName card = Face.name (NonEmpty.head (Card.Type.faces card))

-- CR 608.2d: can this clause's instructions not be carried out AT ALL on this
-- board? What the rule turns on is that "the player can't choose an option
-- that's illegal or impossible", so an option the engine offers has to be one
-- the rules leave to choose -- Resolve.exercises' printed "may" and
-- Resolve.chosenBranch's either-or are the two offers, and both consult this.
--
-- A CLASSIFICATION the consumers see as a Bool, never an identity: the case
-- lives beside applyOneEffect, this module being the one legitimate home of
-- `case effect of`, and Parun.Engine.Resolve reads only the answer.
--
-- ALL its effects and not any, clauseIsInert's shape: an option some of whose
-- instructions can happen is carried out as much as possible (CR 609.3) and is
-- still an option, so a clause is impossible only when every instruction in it
-- is -- effectIsImpossible says what that means for one instruction.
--
-- An instruction acting only on what an EARLIER instruction of the same clause
-- binds is left out of that test, its fate being its definer's: Carth the
-- Lion's "you may reveal a planeswalker card from among them and put it into
-- your hand" moves nothing when the reveal found nothing. Parun.MassEffectSpec's
-- "CR 608.2d Carth the Lion's reveal is not offered without a planeswalker among
-- them" proves it. A PlayerRef naming no slot ("you") is no such read and
-- leaves the instruction dependent; one naming a slot is a read of its own, so
-- the instruction is weighed. Parun.MassEffectSpec's "CR 608.2d a GainControl to
-- you of a slot the reveal defines is dependent on it" proves the first half.
--
-- An EMPTY clause is not impossible, for the reason clauseIsInert gives.
clauseIsImpossible :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GameState -> Clause.Clause Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Bool
clauseIsImpossible resolving source controller legal gs clause =
  let effects = Foldable.toList (Clause.effects clause)
      definedBefore = List.scanl (\defined effect -> Set.union defined (boundSlots effect)) Set.empty effects
      readsOnly defined ref = case ref of
        ObjectRef.InSlot slot -> Set.member slot defined
        ObjectRef.FromAnywhere (FromAnywhere.MkFromAnywhere slot among) -> all (`Set.member` defined) (slot : Foldable.toList among)
        ObjectRef.AllOf refs -> all (readsOnly defined) refs
        _ -> False
      dependent defined effect =
        let refs = effectObjectRefs effect
         in not (null refs) && all (Map.null . playerRefSlots) (effectPlayerRefs effect) && all (readsOnly defined) refs
      independent = [effect | (defined, effect) <- zip definedBefore effects, not (dependent defined effect)]
   in not (null independent) && all (effectIsImpossible resolving source controller legal gs) independent

-- clauseIsImpossible's per-opcode half: the CR 608.2d question one instruction
-- at a time.
--
-- Impossible means the instruction NAMES its subjects and not one of them can
-- undergo it, so nothing at all happens. An instruction naming NOBODY is never
-- impossible -- an empty sweep is vacuously carried out (CR 609.3), and that is
-- also what keeps a slot a sibling effect of the same clause will define (Carth
-- the Lion's Reveal then MoveToZone) from reading as impossible while it is
-- still unbound. Drawing is never impossible either (CR 121.3), nor is
-- searching (CR 701.23b's fail to find). Three arms ask more than "nothing at
-- all happens": Effect.Mill, because rule 701.17b states the whole comparison
-- itself, and a counted discard or sacrifice, where an instruction to give up N
-- things is not an option for a player holding fewer (The Mimeoplasm's
-- 2011-09-22 ruling, "You can't choose to exile just one creature card").
--
-- Exhaustive with no wildcard, ownSlotsAreExhaustive's shape and for its reason:
-- a new opcode must answer here. Each arm below mirrors the read its
-- applyOneEffect arm performs, so the offer and the execution cannot disagree.
-- An arm answering False is one whose instruction always does something, or
-- one no printed "may" reaches.
effectIsImpossible :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GameState -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Bool
effectIsImpossible resolving source controller legal gs effect = case effect of
  Effect.DealDamage {} -> False
  Effect.Fight {} -> False
  Effect.ModifyTarget {} -> False
  Effect.ChangeText {} -> False
  Effect.AddMana {} -> False
  Effect.Firebend {} -> False
  Effect.ActivateManaAbilities {} -> False
  Effect.MoveMana {} -> False
  Effect.Search {} -> False
  Effect.ExileAllGraveyards {} -> False
  Effect.RestartGame {} -> False
  Effect.ControlPlayerNextTurn {} -> False
  Effect.ControlPlayerThisResolution {} -> False
  Effect.Destroy {} -> False
  Effect.Sacrifice {} -> False
  Effect.Attach {} -> False
  Effect.AttachAsThoughCreature {} -> False
  Effect.AttachTarget {} -> False
  Effect.AttachTargetToEach {} -> False
  Effect.AttachBound {} -> False
  Effect.AttachAll {} -> False
  -- CR 701.3d: the sweep names at least one permanent and none of them is
  -- attached to anything, so there is nothing to move away (Akiri, Fearless
  -- Voyager's "you may unattach"). A regression fence: no printed "may" in
  -- data/cards reaches it.
  Effect.Unattach ref ->
    let named = objectRefObjects legal resolving controller source gs ref
     in not (null named) && all ((== Just Nothing) . fmap Object.attachedTo . flip Game.lookupObject gs) named
  Effect.MoveToZone (MoveToZone.MkMoveToZone ref _ _ _ _ _ _) -> choosesFromNothing ref
  Effect.Draw {} -> False
  -- CR 701.17b: "a player can't mill a number of cards greater than the number
  -- of cards in their library. If given the choice to do so, they can't choose
  -- to take that action." The rule states the whole comparison and not merely
  -- the empty library, so this is the one opcode whose impossibility is not the
  -- shared "nothing at all happens" test. Not CR 121.3's carve-out either --
  -- that one is for drawing alone. The millers and the per-miller amount are the
  -- executing arm's own reads.
  Effect.Mill (Mill.MkMill ref quantity _ _) ->
    let millers = playerRefPlayers legal resolving source controller gs ref
        beyondLibrary pid = case evaluateForRecipient viewOf context gs resolving source pid quantity of
          Just n | n > 0 -> n > List.genericLength (Game.zoneMembers Zone.Library pid gs)
          _ -> False
     in not (null millers) && all beyondLibrary millers
  Effect.Reveal (Reveal.MkReveal ref _) -> choosesFromNothing ref
  Effect.FromOutsideTheGame {} -> False
  Effect.ExileThisSpell {} -> False
  Effect.LookAt (LookAt.MkLookAt ref _ _) -> choosesFromNothing ref
  Effect.ArrangeInLibrary {} -> False
  Effect.Scry {} -> False
  Effect.Surveil {} -> False
  Effect.Fateseal {} -> False
  -- CR 701.30 states no precondition: a player with an empty library clashes
  -- anyway, revealing nothing, so nothing here refuses the instruction.
  Effect.Clash {} -> False
  Effect.AsYouCascade {} -> False
  Effect.Explore {} -> False
  Effect.Connive {} -> False
  -- "Discard THESE cards" names the cards themselves, so a sweep matching none
  -- is the naming-nobody case; only a chosen card can be impossible.
  Effect.Discard (Discard.These (TheseDiscard.MkTheseDiscard ref _)) -> choosesFromNothing ref
  -- CR 107.1c: zero is a legal answer, so no hand makes it impossible.
  Effect.Discard (Discard.AnyNumber {}) -> False
  Effect.Discard (Discard.Counted (CountedDiscard.MkCountedDiscard ref quantity _)) ->
    -- CR 701.9a: the victims are the players the reference names, read through
    -- playerRefPlayers as the executing arm reads them, and the amount is read
    -- per victim because a card may count something about them.
    -- Short of the count is impossible, not merely an empty hand: Thrilling
    -- Discovery's "you may discard two cards" over a one-card hand is
    -- Parun.ResolveSpec's "CR 608.2d Thrilling Discovery's discard of two is not
    -- offered over a one-card hand".
    let victims = playerRefPlayers legal resolving source controller gs ref
        shortHanded victim = case evaluateForRecipient viewOf context gs resolving source victim quantity of
          Just n | n > 0 -> n > List.genericLength (Game.zoneMembers Zone.Hand victim gs)
          _ -> False
     in not (null victims) && all shortHanded victims
  Effect.LoseLife {} -> False
  Effect.GainLife {} -> False
  Effect.ExchangeLifeTotals {} -> False
  Effect.ExchangeValues {} -> False
  -- CR 701.12f: an exchange with an empty zone still happens.
  Effect.ExchangeZones {} -> False
  -- CR 701.12a: either side naming nothing it can exchange stops both -- a
  -- source that has left the battlefield or phased out is not exchangeable,
  -- and a hand holding no card the filter admits offers nothing to exchange it
  -- with (CR 702.65b).
  Effect.ExchangeCardZones (ExchangeCardZones.MkExchangeCardZones one other) -> any (\ref -> choosesFromNothing ref || namesOnlyTheGone ref) [one, other]
  Effect.SetLifeTotal {} -> False
  -- CR 608.2d: never impossible. Every player the reference can name is one
  -- Game.stillPlaying answered, and a target who has already left the game is an
  -- illegal target CR 608.2b drops before this is asked.
  Effect.LoseGame {} -> False
  Effect.WinGame {} -> False
  Effect.DrawGame {} -> False
  Effect.RedistributeLifeTotals {} -> False
  Effect.IncreaseSpeed {} -> False
  Effect.DecreaseSpeed {} -> False
  Effect.Create {} -> False
  Effect.Conjure {} -> False
  Effect.CreateCopy {} -> False
  Effect.BecomeCopy {} -> False
  Effect.CopyStackObject {} -> False
  Effect.ChooseNewTargets {} -> False
  Effect.ChangeTargets {} -> False
  Effect.Replace {} -> False
  Effect.SkipPhase {} -> False
  Effect.PreventNextDamage {} -> False
  Effect.PreventAllDamage {} -> False
  Effect.PreventNextDamageInstance {} -> False
  Effect.RedirectDamage {} -> False
  Effect.Counter {} -> False
  Effect.PutCounters {} -> False
  Effect.Divide {} -> False
  -- CR 122.1 / 608.2d: a permanent bearing none of the kind has none of
  -- them to lose.
  Effect.RemoveCounters (RemoveCounters.MkRemoveCounters kind quantity slot _) -> case legalOne slot legal >>= Recipient.objectOf of
    Nothing -> False
    Just target -> case Quantity.evaluateFor viewOf context gs resolving source quantity of
      Just n | n > 0 -> maybe False ((== 0) . Map.findWithDefault 0 kind . Object.counters) (Game.lookupObject target gs)
      _ -> False
  -- CR 608.2d: "remove three" is not an option where fewer are there. "Up to"
  -- and "any number" always are, none being an answer.
  Effect.RemoveCountersAmong (RemoveCountersAmong.MkRemoveCountersAmong count fromRef which _) -> case count of
    RemovalCount.Exactly quantity -> case Quantity.evaluateFor viewOf context gs resolving source quantity of
      Just n | n > 0 -> toInteger (sum (fmap sum (removableAmong gs which (objectRefObjects legal resolving controller source gs fromRef)))) < n
      _ -> False
    RemovalCount.UpTo _ -> False
    RemovalCount.AnyNumber -> False
  -- CR 122.5: every pair the move names fails one of the rule's
  -- impossibilities, so no counter can cross. The pair guard and the movable
  -- kinds are the executing arm's own (movablePair, movableCounters), and
  -- kindsCanCross mirrors its per-MovedKinds reads.
  Effect.MoveCounters (MoveCounters.MkMoveCounters fromRef kinds _ toRef) ->
    let named = objectRefObjects legal resolving controller source gs
        pairs = [(from, to) | from <- named fromRef, to <- named toRef]
        crosses (from, to) = movablePair gs from to && kindsCanCross gs from to kinds
     in not (null pairs) && not (any crosses pairs)
  Effect.PutCountersFrom {} -> False
  Effect.GainPlayerCounters {} -> False
  Effect.RemovePlayerCounters {} -> False
  Effect.PayAnyEnergy {} -> False
  Effect.ChooseNumber {} -> False
  Effect.BindAmount {} -> False
  -- CR 701.26a: "only untapped permanents can be tapped", which is what
  -- Parun.Engine.Event.tap enforces, so a sweep whose every permanent is already
  -- tapped taps nothing.
  Effect.Tap (Tap.MkTap ref _) -> noneNamedIs TapState.Untapped ref
  -- CR 701.26b, tap's mirror and Parun.Engine.Event.untap's own guard.
  Effect.Untap ref -> noneNamedIs TapState.Tapped ref
  Effect.Detain {} -> False
  Effect.Goad {} -> False
  Effect.Pair {} -> False
  Effect.DoesNotUntapNext {} -> False
  -- CR 701.27a/c-f and CR 701.28a/c-f: turnPermanentsOver's own membership
  -- test, so "you may transform" is not offered where nothing named turns over
  -- -- a Clone of a double-faced permanent (CR 701.27c) above all. Parun.TransformSpec's
  -- "CR 608.2d a Clone of Aang, Master of Elements is not offered the
  -- transform" proves it.
  Effect.Transform ref -> nothingTurnsOver ref
  Effect.Convert ref -> nothingTurnsOver ref
  Effect.Flip {} -> False
  Effect.Meld {} -> False
  Effect.PhaseOut {} -> False
  Effect.TurnFaceDown {} -> False
  -- CR 708, Event.turnFaceUpByEffect's own guard: only a face-down
  -- permanent on the battlefield turns face up. A regression fence: the one
  -- "may" in data/cards reaching this opcode, Hauntwoods Shrieker's, targets a
  -- face-down permanent, so CR 608.2b drops a face-up one first.
  -- A slot naming nobody is never impossible, the haddock's invariant.
  Effect.TurnFaceUp slot ->
    let named = objectRefObjects legal resolving controller source gs (ObjectRef.InSlot slot)
     in not (null named) && not (any (\target -> Set.member target (GameState.battlefield gs) && maybe False (Facing.isFaceDown . Object.facing) (Game.lookupObject target gs)) named)
  Effect.RemoveFromCombat {} -> False
  Effect.BecomesBlocked {} -> False
  Effect.SwitchBlockers {} -> False
  Effect.ExchangeBlocks {} -> False
  Effect.AddPhases {} -> False
  Effect.EndTurn {} -> False
  Effect.EndCombatPhase {} -> False
  Effect.GainControl {} -> False
  Effect.ExchangeControl {} -> False
  Effect.SetOwner {} -> False
  Effect.ExchangeOwnership {} -> False
  Effect.ArmDelayedTrigger {} -> False
  Effect.AffectPlayers {} -> False
  Effect.RequireBlock {} -> False
  Effect.Prohibit {} -> False
  Effect.RequireAttack {} -> False
  Effect.ForbidAttack {} -> False
  Effect.ForbidBeingBlocked {} -> False
  Effect.CreateEmblem {} -> False
  Effect.BecomeMonarch {} -> False
  Effect.TakeTheInitiative {} -> False
  Effect.Designate {} -> False
  Effect.SetClassLevel {} -> False
  Effect.Unsuspect {} -> False
  -- CR 709.5f/g: locking chooses an UNLOCKED half of the Room and unlocking a
  -- locked one, so a Room holding no half of the wanted kind has nothing to
  -- choose among. Both readers are the executing arm's.
  Effect.SetHalfLocked (SetHalfLocked.MkSetHalfLocked _ locked slot) -> case legalOne slot legal >>= Recipient.objectOf of
    Nothing -> False
    Just target -> null (if locked then Room.unlockedHalves target gs else Room.lockedHalves target gs)
  Effect.CounterAndMark {} -> False
  Effect.BecomeProtector {} -> False
  Effect.Mentor {} -> False
  Effect.Exploit -> False
  Effect.GiveGift -> False
  Effect.ItBecomes {} -> False
  Effect.ExileHaunting {} -> False
  Effect.PlaySubgame {} -> False
  Effect.ChoosePlayer {} -> False
  Effect.ChooseSector {} -> False
  Effect.ChoosePlayerAtRandom {} -> False
  -- The ask askingObjects makes of the same choice, so "choose a creature"
  -- over an empty board is impossible and "up to" never is.
  Effect.ChoosePermanents (ChoosePermanents.MkChoosePermanents choice _ _) -> choosesFromNothing (ObjectRef.ChosenPermanents choice)
  Effect.RollDie {} -> False
  Effect.FlipCoin {} -> False
  Effect.Guess guess -> choosesFromNothing (Guess.subject guess)
  Effect.ExileHandThenDraw {} -> False
  Effect.NoteManaSpent {} -> False
  Effect.Proliferate {} -> False
  Effect.Reroll -> False
  Effect.RerollStoredResults _ -> False
  Effect.ChooseCardName {} -> False
  Effect.ChooseQuality _ -> False
  Effect.Bolster {} -> False
  Effect.Amass {} -> False
  Effect.Blight {} -> False
  Effect.Earthbend {} -> False
  Effect.Airbend {} -> False
  Effect.TemptWithTheRing {} -> False
  -- CR 609.3: an empty Attraction deck opens nothing.
  Effect.OpenAttraction -> null (Attraction.deckOf controller gs)
  -- The Unstable FAQ: assembling from an empty Contraption deck does nothing.
  Effect.Assemble _ -> null (Game.sideDeckOf SideDeck.Contraption controller gs)
  -- CR 701.31a: only the planar controller of a Planechase game planeswalks.
  Effect.Planeswalk -> not (Planechase.canPlaneswalk controller gs)
  Effect.ChaosEnsues -> False
  -- CR 701.33a: only a face-up ongoing scheme may be abandoned.
  Effect.Abandon -> not (Archenemy.canAbandon source gs)
  Effect.ClaimPrize -> False
  -- CR 701.61a: neither half of forage can be carried out by a player holding
  -- fewer than three cards in their graveyard who controls no Food, which is
  -- Parun.Engine.Forage.canForage. The executing arm reads the same two pools.
  Effect.Forage -> not (Forage.canForage controller gs)
  -- CR 701.36b states the empty board's outcome outright -- "if you control no
  -- creature tokens when instructed to populate, you won't create a token" -- so
  -- populating is a legal no-op rather than something CR 608.2d refuses.
  Effect.Populate -> False
  Effect.TimeTravel -> False
  -- CR 701.70a states no precondition: a player with an empty library or an
  -- empty hand recruits anyway, performing what it can, so nothing here refuses
  -- the instruction.
  Effect.Recruit -> False
  -- CR 701.48a is two "you may"s, and declining both is an outcome the rule
  -- states rather than an impossibility, so nothing here refuses the offer.
  Effect.Learn -> False
  -- CR 701.58a names the top card of a library, and a player whose library is
  -- empty simply has none: CR 609.3 leaves the rest of the effect to do as much
  -- as it can rather than CR 608.2d refusing the instruction.
  Effect.Cloak {} -> False
  Effect.ManifestDread {} -> False
  Effect.Venture {} -> False
  -- CR 608.2d / 701.21a: a player controlling fewer permanents the edict matches
  -- than it counts cannot sacrifice that many. Through
  -- Replacement.sacrificeCandidates, so CR 101.2's "can't be sacrificed" narrows
  -- the pool here exactly as it does in the executing arm, and the amount is read
  -- per victim there too. Parun.ResolveSpec's "CR 608.2d Giant Opportunity's
  -- sacrifice of two Foods is not offered with one Food" proves the count.
  Effect.PlayerSacrifices (PlayerSacrifices.MkPlayerSacrifices players filter_ quantity _) ->
    let victims = playerRefPlayers legal resolving source controller gs players
        tooFewToGive victim = case evaluateForRecipient viewOf context gs resolving source victim quantity of
          Just n | n > 0 -> n > List.genericLength (Replacement.sacrificeCandidates (Filter.perspective context) (Binding.recipientsBySlot legal (slotBindings resolving gs)) victim (Just source) filter_ gs)
          _ -> False
     in not (null victims) && all tooFewToGive victims
  -- CR 701.38b lists the choices, and an object vote's empty list is the
  -- naming-nobody case: nobody votes and nothing is bound, which CR 609.3
  -- carries out vacuously. A word vote's list is printed, so it cannot be empty.
  Effect.Vote {} -> False
  Effect.Bid {} -> False
  Effect.TakeExtraTurn {} -> False
  Effect.ShuffleIntoLibrary {} -> False
  -- CR 608.2d / 407.4: the instruction names anteing players and not one named
  -- object is theirs to ante -- Amulet of Quoz's target with an empty library.
  -- An instruction naming no player is never impossible (an unbound
  -- `thoseWhoMay` before the "may" is asked).
  Effect.Ante (Ante.MkAnte player ref _) ->
    let anteing = playerRefPlayers legal resolving source controller gs player
        named = objectRefObjects legal resolving controller source gs ref
        theirs oid = case Game.lookupObject oid gs of
          Just obj -> List.elem (Object.owner obj) anteing
          Nothing -> False
     in not (null anteing) && not (any theirs named)
  -- CR 608.2d / 123.3: no placer has a sticker of an allowed kind it can put
  -- on a named object it owns, at its cost and cap. The ChosenPermanents and
  -- ChosenCardInGraveyard reads are the candidate sets chosenPermanents and
  -- chosenCardsInGraveyard offer, the pure sweep answering nothing for them.
  Effect.PutSticker (PutSticker.MkPutSticker player ref kinds cap free _) ->
    let placers = playerRefPlayers legal resolving source controller gs player
        named = case ref of
          ObjectRef.ChosenPermanents choice -> chosenCandidates legal resolving controller source gs choice
          ObjectRef.ChosenCardInGraveyard (ChosenCardInGraveyard.MkChosenCardInGraveyard chooser scope filter_ _) -> case chooser of
            Chooser.BoundInSlot slot -> case playerRefPlayers legal resolving source controller gs (PlayerRef.InSlot slot) of
              [pid] | List.elem pid (Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) legal scope gs) -> graveyardCardsOf context gs pid filter_
              _ -> []
            Chooser.TheController -> graveyardCards context legal source controller gs scope filter_
            Chooser.EachInScope -> graveyardCards context legal source controller gs scope filter_
          _ -> objectRefObjects legal resolving controller source gs ref
        owns pid oid = fmap Object.owner (Game.lookupObject oid gs) == Just pid
        placeable pid = any (\oid -> owns pid oid && not (null (Sticker.offered pid oid kinds (ticketCapOf resolving source controller legal gs cap) free gs))) named
     in not (null placers) && not (any placeable placers)
  Effect.Shuffle {} -> False
  Effect.OfferCast {} -> False
  Effect.OfferNamedCopy {} -> False
  Effect.OfferNotedCopy {} -> False
  Effect.GrantPlayFromExile {} -> False
  Effect.GrantLookAtExiled {} -> False
  Effect.MakePlotted {} -> False
  Effect.MakeForetold {} -> False
  Effect.MakeWarped {} -> False
  Effect.ForEach {} -> False
  Effect.ForEachNumber {} -> False
  Effect.Repeat {} -> False
  Effect.RepeatIf {} -> False
  -- CR 701.69a removes marked damage, so permanents bearing none have nothing
  -- to lose. A regression fence: no printed "may" in data/cards reaches it.
  Effect.Heal ref ->
    let named = objectRefObjects legal resolving controller source gs ref
     in not (null named) && all ((== Just 0) . fmap Object.damage . flip Game.lookupObject gs) named
  where
    viewOf = effectViewOf resolving source legal gs
    context = effectContext gs resolving controller source legal (slotBindings resolving gs)
    -- The tap-state half of Effect.Tap's and Effect.Untap's arms: the sweep
    -- names at least one permanent and none of them is in the state the
    -- instruction needs to find.
    nothingTurnsOver ref =
      let named = objectRefObjects legal resolving controller source gs ref
       in not (null named) && not (any (turnsOver (Projection.projectAll gs) resolving gs) named)
    noneNamedIs state ref =
      let named = objectRefObjects legal resolving controller source gs ref
       in not (null named) && not (any ((== Just state) . fmap Object.tapped . flip Game.lookupObject gs) named)
    -- CR 608.2d for the refs that ASK rather than read: a chosen card or
    -- permanent is an instruction to choose one, and an empty pool leaves
    -- nothing to choose. Each pool is its asking arm's own read
    -- (chooseCardsInHand, chosenCardsInGraveyard,
    -- chooseCardFromAmong, chosenPermanents), and a random card in hand is the
    -- same pick with randomness choosing; a ref naming no chooser, a choice
    -- the empty answer satisfies, and every ref that reads, answers False.
    choosesFromNothing ref = case ref of
      ObjectRef.ChosenCardInHand (ChosenCardInHand.MkChosenCardInHand player filter_ count) ->
        let choosers = handChoosers legal resolving source controller gs player
         in positive count && not (null choosers) && all (\pid -> null (handCardsOf context gs pid filter_)) choosers
      -- randomCardsInHand's pool: Pillaging Horde's "unless you discard a card
      -- at random" over an empty hand (CR 118.3, 118.12a), which the scenario
      -- "CR 118.3 Pillaging Horde is sacrificed over an empty hand" proves.
      ObjectRef.RandomCardInHand (RandomCardInHand.MkRandomCardInHand player filter_ _) ->
        let holders = handChoosers legal resolving source controller gs player
         in not (null holders) && all (\pid -> null (handCardsOf context gs pid filter_)) holders
      ObjectRef.ChosenCardInGraveyard (ChosenCardInGraveyard.MkChosenCardInGraveyard chooser scope filter_ count) ->
        positive count && case chooser of
          Chooser.TheController -> null (graveyardCards context legal source controller gs scope filter_)
          Chooser.EachInScope ->
            let scoped = Target.zoneScopePlayers (Plane.rangePerspective source controller gs) (Just controller) legal scope gs
             in not (null scoped) && all (\pid -> null (graveyardCardsOf context gs pid filter_)) scoped
          Chooser.BoundInSlot _ -> False
      ObjectRef.ChosenCardFromAmong (ChosenCardFromAmong.MkChosenCardFromAmong slot filter_ count _ _) ->
        mustPick count && maybe False (null . matchingFromAmong legal resolving controller source gs filter_ . stillPresent gs) (fromAmongBound slot)
      ObjectRef.ChosenPermanents choice -> mustPick (ChosenPermanents.count choice) && null (chosenCandidates legal resolving controller source gs choice)
      -- Only when no member names anything: a read always might.
      ObjectRef.AllOf refs -> all choosesFromNothing refs
      _ -> False
    -- A read that names objects, none of them exchangeable.
    namesOnlyTheGone ref =
      let named = objectRefObjects legal resolving controller source gs ref
       in not (null named) && not (any (`exchangeable` gs) named)
    positive quantity = maybe False (> 0) (Quantity.evaluateFor viewOf context gs resolving source quantity)
    -- An exact count of at least one; "up to" is satisfied by the empty answer.
    mustPick count = case count of
      HowMany.Exactly quantity -> positive quantity
      HowMany.UpTo _ -> False
    -- fromAmongMembers' three reads, pure, with a fourth answer: a slot nothing
    -- has bound yet is Nothing, the naming-nobody case a sibling will define.
    fromAmongBound slot = case slotGroup slot resolving gs of
      Just objects -> Just (Foldable.toList objects)
      Nothing
        | Map.member slot legal -> Just (Maybe.mapMaybe Recipient.objectOf (legalMany slot legal))
        | otherwise -> fmap (: []) (slotOne slot resolving gs)

-- CR 400.7: the members of a group that are still in the game. One that has
-- left is a new object, so it is no card "from among them" to choose, though CR
-- 608.2h still answers a read of it (effectViewOf). Shared by the choice and
-- effectIsImpossible's check of it, so a "may" (CR 608.2d) and the choice cannot
-- disagree. Telling Time's second pick, made after the first moved a card to
-- hand, is the case: the scenario "telling-time-over-two-cards-offers-no-second-
-- choice" proves the choice. The check's use is a REGRESSION FENCE: no card in
-- data/cards/ (2026-10-27) has a "may" clause choosing an exact number from a
-- group an earlier clause of its mode acted on.
stillPresent :: GameState -> [ObjectId] -> [ObjectId]
stillPresent gs = filter (\oid -> Maybe.isJust (Game.lookupObject oid gs))

-- Whether an exchange of zones (CR 701.12d) can take this object: it is still
-- in the game (CR 400.7) and not phased out, which CR 702.26b treats as though
-- it doesn't exist. Shared by the ExchangeCardZones arm and effectIsImpossible,
-- so the offer and the exchange cannot disagree. Parun.AuraSpec's "CR 702.26b"
-- AuraSwap case is the proof.
exchangeable :: ObjectId -> GameState -> Bool
exchangeable oid gs = Maybe.isJust (Game.lookupObject oid gs) && not (Phasing.isPhasedOut oid gs)

-- CR 122.5's first and fourth impossibilities for one pair: the two objects
-- differ and both are on the battlefield. Shared by the MoveCounters arm and
-- effectIsImpossible, so the offer and the move cannot disagree.
movablePair :: GameState -> ObjectId -> ObjectId -> Bool
movablePair gs from to = from /= to && Set.member from (GameState.battlefield gs) && Set.member to (GameState.battlefield gs)

-- The kinds on the first object that can cross: present, and not refused by
-- the second (CR 122.5's second and third impossibilities). The MoveCounters
-- arm's `onFrom`.
movableCounters :: GameState -> ObjectId -> ObjectId -> Map.Map (CounterKind.CounterKind Keyword.Type.Keyword) Natural
movableCounters gs from to =
  Map.filterWithKey
    (\kind n -> n > 0 && not (CounterRestriction.prohibited to kind gs))
    (maybe Map.empty Object.counters (Game.lookupObject from gs))

-- Whether any kind the MovedKinds arm would move is among movableCounters: the
-- named kind for the arms naming one, an absent kind for EachAbsentKind, and any
-- kind at all otherwise.
kindsCanCross :: GameState -> ObjectId -> ObjectId -> MovedKinds.MovedKinds -> Bool
kindsCanCross gs from to kinds =
  let onFrom = movableCounters gs from to
   in case kinds of
        MovedKinds.Named wanted _ -> Map.member wanted onFrom
        MovedKinds.EveryOfKind wanted -> Map.member wanted onFrom
        MovedKinds.AnyNumberOfKind wanted -> Map.member wanted onFrom
        MovedKinds.EachAbsentKind ->
          let onTo = Map.filter (> 0) (maybe Map.empty Object.counters (Game.lookupObject to gs))
           in not (Map.null (Map.withoutKeys onFrom (Map.keysSet onTo)))
        MovedKinds.Every -> not (Map.null onFrom)
        MovedKinds.Chosen _ -> not (Map.null onFrom)
        MovedKinds.AnyNumber -> not (Map.null onFrom)
        MovedKinds.AtLeastOne -> not (Map.null onFrom)
        MovedKinds.UpToOneChosen -> not (Map.null onFrom)

-- | Log one ballot, shown to every player still in the game in an open vote
-- (CR 101.4b) and, in a secret one, to the voter and the player making their
-- decisions (CR 723.4).
logBallot :: Bool -> Ballot.Ballot -> Game ()
logBallot secret ballot = do
  gs <- State.get
  let audience =
        if secret
          then Decide.privyTo (Ballot.voter ballot) gs
          else Set.fromList (Game.stillPlaying gs)
  State.modify' (Event.recordEvent (GameEvent.Voted (Voted.MkVoted ballot audience)))

-- CR 701.34a: one proliferate by `controller`, for an ability of `source`. The
-- Effect.Proliferate arm's body, once per proliferate its CR 614.1a
-- replacements left standing.
proliferateOnce :: ObjectId -> PlayerId -> Game ()
proliferateOnce source controller = do
  gs <- State.get
  let reach = Plane.rangePerspective source controller gs
      everyone = Players.table reach gs
      grants = Projection.controlGrants gs
      kindsOn oid = foldMap (Map.keys . Map.filter (> 0) . Object.counters) (Game.lookupObject oid gs)
      kindsFor pid = foldMap (Map.keys . Map.filter (> 0) . Player.counters) (Map.lookup pid (GameState.players gs))
      -- zoneMembers slices the shared battlefield by OWNER, so the union over
      -- every seat is every permanent in play (CR 701.34a).
      onBattlefield = concatMap (\pid -> Game.zoneMembers Zone.Battlefield pid gs) (Game.stillPlaying gs)
      -- CR 801.10: a permanent in range, whoever owns it -- every one for CR
      -- 801.18's planar source.
      permanents = filter (\oid -> not (null (kindsOn oid)) && all (\you -> Projection.objectInRangeGiven grants you oid gs) reach) onBattlefield
      players = filter (not . null . kindsFor) everyone
  Monad.unless (null permanents && null players) $ do
    (pickedPermanents, pickedPlayers) <-
      Game.choose (Prompt.ChooseProliferate (Decide.deciderFor controller gs) controller permanents players)
    -- FILTERED, NOT TRUSTED: an answer naming something not offered is dropped.
    let keptPermanents = filter (\oid -> Set.member oid pickedPermanents) permanents
        keptPlayers = filter (\pid -> Set.member pid pickedPlayers) players
    -- CR 122.6: object counters through the single funnel, so CR 614's counter
    -- replacements apply to a proliferated counter as to a placed one.
    Monad.forM_ keptPermanents $ \oid ->
      Monad.forM_ (kindsOn oid) $ \kind -> Event.putCounters (CounterCause.ByEffect controller) oid kind 1
    -- CR 122.1: and player counters through their own funnel.
    --
    -- CR 701.34b: a kind a team shares (Game.counterSharers, Two-Headed Giant's
    -- poison) gets one additional counter however many of its members were
    -- chosen.
    --
    -- Not implemented: the proliferating player's choice of WHICH chosen
    -- teammate gets that counter; the first in turn order does (#4795).
    Monad.forM_ (zip [0 :: Int ..] keptPlayers) $ \(i, pid) ->
      Monad.forM_ (kindsFor pid) $ \kind ->
        Monad.unless (any (\earlier -> List.elem pid (Game.counterSharers kind earlier gs)) (take i keptPlayers)) $
          Monad.void (Event.putPlayerCounters (CounterCause.ByEffect controller) pid kind 1)
  -- "Whenever you proliferate" fires even when nothing was chosen (Tekuthal,
  -- Inquiry Dominus's ruling), so the event is recorded outside the guard.
  State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Proliferate controller)))

-- CR 603.7c: stamp the land an earthbend animated onto the resolving object, so
-- the environment the arming opcode captures next carries it. Parun.Engine.Earthbend's
-- delayed ability names Binding.earthbentLand and nothing else can supply it: the
-- ability is engine text and cannot know what a card called its own target slot.
--
-- Written as a TARGET binding because Binding.objectSlots -- what the condition
-- reads -- is the targets field. Not a target in CR 115.10a's sense: the choice
-- was made by the spell or ability that earthbent, and CR 608.2b re-checked it
-- before this arm ran.
bindEarthbentLand :: ObjectId -> ObjectId -> GameState -> GameState
bindEarthbentLand resolving land gs =
  let put obj = obj {Object.bindings = Map.insert Binding.earthbentLand (Binding.toObject land) (Object.bindings obj)}
   in gs {GameState.objects = Map.adjust put resolving (GameState.objects gs)}

-- CR 702.165a's grant, expanded as the ability RESOLVES: one ordinary
-- modification per ability the source carries, so what is stored outlives the
-- creature with backup exactly as "until end of turn" says it must. Every other
-- modification passes through as the one it already is.
--
-- A LIST, so a source with nothing to grant stores no effect at all rather than
-- one with no content, and so the arm never has to reach the projection: each
-- grant becomes a GainKeyword or a GainAbility that CR 613.7 timestamps and CR
-- 613.1f applies like any other. Several timestamps where the rule states one
-- effect, which no board can tell apart -- every part of this grant is an
-- APPEND to a layer-6 list, and appends do not compete for order.
--
-- Read off the COPIABLE characteristics (CR 707.2), never the printed face: CR
-- 702.165b grants what a permanent that entered as a copy of a card with backup
-- copied, and CR 702.165c keeps out every ability a later effect gave it.
--
-- And read as they were when the ability was put on the stack, which is CR
-- 702.165d: Parun.Engine.Engine.placeBorne stamped them on the resolving object
-- (Binding.placedSourceCopyOf), so a source destroyed or turned into a copy of
-- something else in response still grants what it had. The live read is the
-- fallback for an object that carries no stamp. Parun.KeywordTriggerSpec's
-- Backup group's two CR 702.165d cases prove it.
--
-- The KEYWORDS are granted one modification per written instance, CR 613.1f's
-- reading that Parun.Engine.Projection.applyModification's GainKeyword arm
-- already takes: a card printing a keyword twice grants it twice. Backup's own
-- family is dropped, rule 702.165a's "non-backup", and so is every keyword the
-- card prints ABOVE this backup line, its "printed below this one" (Saiba
-- Cryptomancer's flash).
--
-- A STATIC ability travels the same way, as a GainAbility that the projection
-- gathers from its new host (Parun.Engine.Projection.View's
-- grantedStaticAbilitiesOf); Streetwise Negotiator's is the one in the pool.
-- The copiable list holds no ability rule 702 mints from a keyword
-- (Keyword.mintedStaticAbilitiesOf), so none is granted twice.
--
-- The RULE abilities (CR 613.11) travel as one GainAbility carrying the whole
-- bundle, gathered from the new host beside its own
-- (Parun.Engine.Projection.grantedRuleAbilities); Chomping Kavu's is the one in
-- the pool. A REPLACEMENT effect and a PLAYER ability each travel as their own
-- GainAbility, gathered into the new host's projected lists; unproven, since no
-- printing with backup prints either, nor a special action, which has no arm
-- (Scryfall `keyword:backup`, 2026-09-24).
expandGrant :: ObjectId -> ObjectId -> GameState -> Modification.Modification (GrantedAbility.GrantedAbility Card.Type.Card) -> [Modification.Modification (GrantedAbility.GrantedAbility Card.Type.Card)]
expandGrant resolving source gs modification = case modification of
  Modification.GainAbilitiesOfSource above ->
    let pc = Maybe.fromMaybe (Projection.copiableCharacteristics source gs) (Binding.placedSourceCopyOf (slotBindings resolving gs))
        printedAbove keyword = Set.member keyword above
        granted keyword count
          | Keyword.familyOf keyword == Just KeywordFamily.Backup = []
          | printedAbove keyword = []
          | otherwise = List.genericReplicate count (Modification.GainKeyword keyword)
     in concatMap (uncurry granted) (Map.toAscList (PC.keywords pc))
          <> fmap (Modification.GainAbility . GrantedAbility.Activated) (PC.activatedAbilities pc)
          <> fmap (Modification.GainAbility . GrantedAbility.Triggered) (PC.triggeredAbilities pc)
          <> fmap (Modification.GainAbility . GrantedAbility.Static) (PC.staticAbilities pc)
          <> [Modification.GainAbility (GrantedAbility.Rules (PC.ruleAbilities pc)) | PC.ruleAbilities pc /= mempty]
          <> fmap (Modification.GainAbility . GrantedAbility.Replacement) (PC.replacementEffects pc)
          <> fmap (Modification.GainAbility . GrantedAbility.Player) (PC.playerAbilities pc)
          <> fmap (Modification.GainAbility . GrantedAbility.SelfCostReduction) (PC.costReductions pc)
  _ -> [modification]

-- CR 614.12: the other permanents that entered in the same event as `oid` (CR
-- 608.2f's group, which an Event.simultaneously bracket shares) -- not yet on the
-- battlefield as its entry's replacement effects apply. Ixidron's ruling: "If
-- Ixidron and another creature are entering at the same time, the other creature
-- enters face up." Read off the log at the drain, since a later member of the
-- batch has not entered when the rewrite queues the effects. Parun.FaceDownSpec's
-- "CR 614.12 a creature entering beside Ixidron enters face up" (one MoveToZone)
-- and Parun.TargetPerPlayerSpec's Sepulchral Primordial pair (a ForEach) prove it.
enteredBeside :: ObjectId -> GameState -> Set ObjectId
enteredBeside oid gs = case Game.entryGroup oid gs of
  Nothing -> Set.empty
  Just group ->
    Set.delete oid . Set.fromList $
      [ ZoneChange.object zc
      | logged <- Foldable.toList (GameState.events gs),
        LoggedEvent.group logged == group,
        Just zc <- [Game.enteredBattlefieldChange (LoggedEvent.event logged)]
      ]

-- | CR 706.8a: note each of these results of a die of `sides` on `target` as
-- a stored result, for the abilities acquired as `acquisition` (CR 607.5).
-- Only a PERMANENT holds stored results, so an object no longer on the
-- battlefield is left alone.
storeOn :: Acquisition.Acquisition -> ObjectId -> Natural -> [Natural] -> GameState -> GameState
storeOn acquisition target sides results gs =
  let noted :: Map.Map StoredResult.StoredResult Natural
      noted = Map.fromListWith (+) [(StoredResult.MkStoredResult {StoredResult.sides = sides, StoredResult.value = result}, 1) | result <- results]
      store o =
        if Object.zone o == Zone.Battlefield
          then o {Object.storedResults = Map.insertWith (Map.unionWith (+)) acquisition noted (Object.storedResults o)}
          else o
   in gs {GameState.objects = Map.adjust store target (GameState.objects gs)}

-- | CR 706.1's roll, as the log records it once throwDice's results are
-- settled.
recordRoll :: PlayerId -> [PlayerId] -> [Natural] -> Game ()
recordRoll controller throwers results = do
  State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.RollDice controller)))
  -- CR 706.2's final number, one entry per die the instruction kept, for
  -- "whenever you roll a 6" -- after every modifier, and never for an ignored
  -- roll (CR 706.6). Recorded under the player who threw the die's final
  -- natural result: Pippa, Duchess of Dice's ruling gives a reroll of another
  -- player's die to the rerolling player's "whenever you roll" triggers.
  Foldable.for_ (zip throwers results) $ \(thrower, result) ->
    State.modify' (Event.recordEvent (GameEvent.DieResultSettled DieResult.MkDieResult {DieResult.roller = thrower, DieResult.result = result}))

-- | The stamp on GameState that ActivationRestriction.DuringDieRoll reads and
-- Effect.Reroll asks against, open for `act` and restored on the way out so a
-- roll nested inside the window's own resolution cannot leave it open.
withRollingDie :: Natural -> Game a -> Game a
withRollingDie sides act = do
  previous <- State.get
  State.modify' (\g -> g {GameState.rollingDie = Just sides, GameState.rerollRequested = False})
  result <- act
  State.modify' (\g -> g {GameState.rollingDie = GameState.rollingDie previous, GameState.rerollRequested = GameState.rerollRequested previous})
  pure result

-- CR 123.6e's "that sticker": bind the placed sticker under @slot@, on
-- bindSlot's holder. Written only when a sticker was placed, so
-- happenedBetween needs no copy-across.
bindStickerSlot :: ObjectId -> SlotName -> StickerRef.StickerRef -> GameState -> GameState
bindStickerSlot holder slot ref = overHolderBindings holder (Map.insert slot (Binding.toSticker ref))

-- CR 123.3c: a placement's ticket-cost cap, evaluated now; an unevaluable
-- cap is zero, so nothing above it is offered.
ticketCapOf :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GameState -> Maybe Quantity.Type.Quantity -> Maybe Natural
ticketCapOf resolving source controller legal gs =
  fmap (maybe 0 Integer.toNaturalSaturating . Quantity.evaluateFor (effectViewOf resolving source legal gs) (effectContext gs resolving controller source legal (slotBindings resolving gs)) gs resolving source)

-- CR 603.7c: bind `target` into `slot` of `holder`'s binding environment, so a
-- delayed ability armed later in the SAME resolution can name the object.
-- `holder` is `resolving` -- the object ON THE STACK -- the same object
-- ArmDelayedTrigger captures from.
--
-- The slot IS visible to a later effect of the same fold: resolveSpellWith and
-- resolveModes each re-read Object.bindings before EACH effect (CR 608.2c), while
-- ArmDelayedTrigger and slotOne read live GameState rather than `chosen`.
bindSlot :: ObjectId -> SlotName -> ObjectId -> GameState -> GameState
bindSlot holder slot target = overHolderBindings holder (Map.insert slot (Binding.toObject target))

-- bindSlot's plural: bind EVERY object one instruction produced into `slot`, for
-- a card that refers back to all of them at once ("those tokens", "those cards",
-- CR 400.7j). Same holder and same further reason (CR 603.7c).
--
-- Readable mid-fold without either path's per-effect re-read, because every
-- reader goes through slotGroup, which reads the live board (resolvingBindings).
-- It has to: this rides the binding's `objects` field, while `chosen` reads only
-- `target`, where bindSlot's SINGLE object lands.
bindObjectsSlot :: ObjectId -> SlotName -> Seq.Seq ObjectId -> GameState -> GameState
bindObjectsSlot holder slot targets = overHolderBindings holder (Map.insert slot (Binding.toObjects targets))

-- CR 701.21a: the permanents the sacrifice funnel SACRIFICED between two states
-- of one resolution, under their battlefield ids, in log order -- never what an
-- instruction named, since a permanent it refused (CR 701.21a's control clause,
-- CR 101.2's "can't") was not sacrificed. Read off the
-- GameEvent.PermanentSacrificed entries, which the funnel records before any CR
-- 614 redirection, so a permanent Rest in Peace exiles instead still counts.
sacrificedBetween :: GameState -> GameState -> [ObjectId]
sacrificedBetween before after =
  [ PermanentWasSacrificed.permanent sacrificed
  | logged <- Foldable.toList (Seq.drop (Seq.length (GameState.events before)) (GameState.events after)),
    GameEvent.PermanentSacrificed sacrificed <- [LoggedEvent.event logged]
  ]

-- The one writer both binders above go through: rewrite the holder's bindings
-- wherever the holder now is. GameState.objects while it is on the stack, and
-- GameState.stackArchive once its own instruction has moved it off -- CR 201.5's
-- self-exile (Chronomantic Escape), where the move DEFINES a slot the clause
-- after it reads and CR 400.7 has already deleted the id it would sit on.
-- Parun.Engine.Resolve.Slots.resolvingBindings is the reading side of the same
-- fact, and Map.adjust makes the half that does not hold the object a no-op.
overHolderBindings :: ObjectId -> (Map.Map SlotName Binding.Type.Binding -> Map.Map SlotName Binding.Type.Binding) -> GameState -> GameState
overHolderBindings holder f gs =
  let put obj = obj {Object.bindings = f (Object.bindings obj)}
   in gs
        { GameState.objects = Map.adjust put holder (GameState.objects gs),
          GameState.stackArchive = Map.adjust put holder (GameState.stackArchive gs)
        }

-- CR 701.8b's "put into a graveyard this way", asked of one CR 400.7 incarnation:
-- is it a card, and is it in a graveyard? Both halves are questions about where
-- the object ended up rather than about the destruction, which is why they are
-- asked of the board after the funnel ran (see Effect.Destroy's arm).
--
-- WHOSE graveyard is not asked: CR 400.3 files the arrival under the owner and
-- no printed reader of this slot distinguishes them. Object.zone is the read
-- because it tracks the zone sets and answers in one lookup; CR 111.6 is the
-- card half.
isCardInAGraveyard :: ObjectId -> GameState -> Bool
isCardInAGraveyard oid gs = case Game.lookupObject oid gs of
  Nothing -> False
  Just obj -> Object.zone obj == Zone.Graveyard && not (Game.isToken oid gs)

-- The default runner for the resolutions the live loop does not drive: a
-- PlaySubgame effect reports a draw and binds nothing. Parun.Engine.Engine passes
-- the real runner to BOTH halves of CR 729.1a's "spell or ability"
-- (resolveSpellWith, resolveModesWith), and to the instructions that never reach
-- the stack: CR 614.1c's as-enters effects, CR 615.5's prevention riders, CR
-- 614.1a's damage-replacement effects, CR 103.5b/103.6's hand actions and CR
-- 605.4a's triggered mana abilities (performManaAbility). Parun.GameSpec's "CR
-- 614.1c / 729.1b gameplay: an as-enters subgame's winner draws a card" proves
-- the as-enters road.
noSubgame :: Game Result
noSubgame = pure Result.Drawn

-- Bind the PLAYERS a resolution named into `slot` on `holder` -- one, or CR
-- 104.2c's winning team -- bindSlot's mirror with player recipients (ToPlayer)
-- rather than objects.
--
-- Every caller passes `resolving` -- the object on the stack, whose bindings both
-- resolution loops re-read before each effect: CR 729.1b's subgame winner and CR
-- 608.2d's chosen opponent are each read by the effect after the one that bound
-- it, through that re-read (`legalNow`).
--
-- A holder that no longer EXISTS writes to GameState.detachedBindings instead,
-- which `liveBindings` reads back. Map.adjust is silent on a missing key, so
-- without that branch the binding is simply dropped.
--
-- CR 729.5 is the branch's reason: a wish cast inside a subgame can take the
-- resolving spell's own card, and "the spell or ability that created the subgame
-- finishes resolving, even if it was created by a spell card that's no longer on
-- the stack" is what keeps the resolution going anyway. It is not the only way an
-- id can cease mid-resolution -- Effect.ExileThisSpell mints a fresh incarnation
-- (CR 400.7) and leaves the old id naming nothing too -- and the read side treats
-- both the same.
--
-- bindPlayersSlot is NOT given the same fallback: its one caller is CR
-- 118.12a's per-player gate, which cannot lose its holder. bindAmountSlot is,
-- for a SPELL's source is the same id a subgame can take.
bindPlayerSlot :: ObjectId -> SlotName -> Set PlayerId -> GameState -> GameState
bindPlayerSlot holder slot players gs =
  let binding = Binding.toPlayers players
      put obj = obj {Object.bindings = Map.insert slot binding (Object.bindings obj)}
   in if Map.member holder (GameState.objects gs)
        then gs {GameState.objects = Map.adjust put holder (GameState.objects gs)}
        else gs {GameState.detachedBindings = Map.insertWith Map.union holder (Map.singleton slot binding) (GameState.detachedBindings gs)}

-- The counters of the kinds a removal reaches on each of these permanents, by
-- kind, the ones carrying none dropped.
removableAmong :: GameState -> WhichCounters.WhichCounters Keyword.Type.Keyword -> [ObjectId] -> Map.Map ObjectId (Map.Map (CounterKind.CounterKind Keyword.Type.Keyword) Natural)
removableAmong gs which candidates = Map.filter (not . Map.null) (Map.fromList [(candidate, Cost.removableCounters which candidate gs) | candidate <- candidates])

-- CR 608.2d: does this answer divide the total among offered permanents, each
-- one it names getting at least one?
distributes :: Natural -> NonEmpty.NonEmpty ObjectId -> Map.Map ObjectId Natural -> Bool
distributes total offered answer =
  sum answer == total
    && all (> 0) answer
    && all (`elem` offered) (Map.keys answer)

-- The objects a RemoveCountersAmong names that carry the kind, with how many
-- each carries: Parun.Engine.Cost.spreadRemovalCandidates' shape.
carrying :: GameState -> CounterKind.CounterKind Keyword.Type.Keyword -> [ObjectId] -> Map.Map ObjectId Natural
carrying gs kind candidates = Map.filter (> 0) (Map.fromList [(candidate, Cost.countersOn kind candidate gs) | candidate <- candidates])

-- A loop's per-run scope (CR 608.2c): the slots its body defines put back to
-- what the resolving object held before the first run, so a run that binds
-- nothing does not read what the previous run bound. Takes the pre-loop state
-- and answers the reset to apply before each run.
rescopeRun :: ObjectId -> Set SlotName -> GameState -> GameState -> GameState
rescopeRun resolving bodyDefined gs0 =
  let bindingsOf gs = maybe Map.empty Object.bindings (Game.lookupObject resolving gs)
      beforeLoop = Map.restrictKeys (bindingsOf gs0) bodyDefined
   in \gs ->
        gs
          { GameState.objects =
              Map.adjust
                (\o -> o {Object.bindings = Map.union beforeLoop (Map.withoutKeys (Object.bindings o) bodyDefined)})
                resolving
                (GameState.objects gs)
          }

-- CR 701.8b: bind how many permanents a destruction actually destroyed into
-- `slot` on `holder`, readable as Quantity.InSlot. Binds a NUMBER, which rides
-- the binding field CR 601.2b's chosen X rides. Left behind after the resolution,
-- harmless and unreadable: only an effect naming this slot can see it, and a
-- second sweep overwrites the value before reading it.
--
-- The holder is the effect's `source`, NOT `resolving`, because an amount is
-- read back by Quantity.evaluateFor aimed at `source` (CR 608.2h) while an
-- object binding is read back by ArmDelayedTrigger off the stack object. Where
-- the source has LEFT (CR 400.7) -- Sensational Spider-Man bounced with its
-- trigger on the stack -- the amount goes on `resolving`, the object
-- Quantity.InSlot falls back to, since CR 113.7a resolves the ability anyway.
-- Parun.RemoveCounterSpec's bounced Spider-Man proves it.
--
-- A copy goes on `resolving` as well when the source is written, so a source
-- that leaves LATER in the same resolution does not take the amount with it
-- (CR 113.7a): Flameblast Dragon sacrificed to Ashnod's Altar while paying for
-- the X it just chose. The scenario
-- flameblast-dragon-keeps-its-x-when-sacrificed-to-pay-for-it proves it.
--
-- Where neither exists -- CR 729.5's resumed resolution, a wish inside the
-- subgame having taken the spell's own card -- the amount goes to
-- GameState.detachedBindings under `resolving`, bindPlayerSlot's fallback, which
-- Quantity.InSlot reads back. Parun.OutsideTheGameSpec's Synthetic Subgame Tithe
-- case proves it.
bindAmountSlot :: ObjectId -> ObjectId -> SlotName -> Natural -> GameState -> GameState
bindAmountSlot resolving source slot n gs =
  let binding = Binding.toAmount n
      put obj = obj {Object.bindings = Map.insert slot binding (Object.bindings obj)}
      holder = if Map.member source (GameState.objects gs) then source else resolving
   in if Map.member holder (GameState.objects gs)
        then gs {GameState.objects = Map.adjust put resolving (Map.adjust put holder (GameState.objects gs))}
        else gs {GameState.detachedBindings = Map.insertWith Map.union resolving (Map.singleton slot binding) (GameState.detachedBindings gs)}

-- CR 119.5 / 701.12c: move a player's life total by a delta. A DOWNWARD delta is
-- a life loss and goes through Event.resolveLifeLoss first, CR 614.1's funnel for
-- the class, so a replacement watching life loss reaches it and the SETTLED loss
-- is what moves the total -- which is why a player may end up somewhere other
-- than the total the effect named. An upward delta is a life GAIN and goes
-- through Event.resolveLifeGain, the same funnel one direction over -- CR 119.5
-- spelling a higher total as the player gaining "the necessary amount of life",
-- and CR 701.12c saying out loud that "replacement effects may modify these gains
-- and losses".
--
-- The one road for every arm that arrives at a TOTAL rather than at an amount:
-- Effect.SetLifeTotal, Effect.ExchangeLifeTotals and
-- Effect.RedistributeLifeTotals.
changeLifeByDelta :: PlayerId -> Integer -> Game ()
changeLifeByDelta pid delta =
  if delta < 0
    then do
      settled <- Event.resolveLifeLoss LifeLossCause.ByEffect pid (Integer.toNaturalSaturating (negate delta))
      Event.changeLife pid (negate (toInteger settled))
    else do
      settled <- Event.resolveLifeGain pid (Integer.toNaturalSaturating delta)
      Event.changeLife pid (toInteger settled)

-- CR 701.23: do to a found card what the search said -- a move, a CR 701.20a
-- reveal, or both, every move through the CR 400.7 funnel.
--
-- Answers what Search.slot binds: the incarnations a move minted (CR 400.7), the
-- found card itself where the instruction only revealed it, and nothing where a
-- move did not happen.
-- CR 400.11b: where a card a search found outside the game arrives, and whether
-- it is shown (CR 701.23e), for a destination that can take one: Invasion of
-- Arcavios's "reveal it, and put it into your hand". Nothing for the rest, which
-- then offers nothing out there -- MTGJSON dump of 2026-08-23, text "search" with
-- "outside the game": Invasion of Arcavios and Turtles Forever, both ending in a
-- hand; a search sending a card from outside the game onto the battlefield would
-- refute it.
outsideArrival :: SearchDestination.SearchDestination -> Maybe (OutsideDestination.OutsideDestination, Bool)
outsideArrival destination = case destination of
  SearchDestination.RevealThenHand -> Just (OutsideDestination.Hand, True)
  SearchDestination.Hand -> Just (OutsideDestination.Hand, False)
  SearchDestination.Battlefield -> Nothing
  SearchDestination.BattlefieldTapped -> Nothing
  SearchDestination.Exile -> Nothing
  SearchDestination.BattlefieldAttachedOrHand -> Nothing
  SearchDestination.BattlefieldAttached -> Nothing
  SearchDestination.Reveal -> Nothing
  SearchDestination.Stay -> Nothing
  SearchDestination.RevealThenTop -> Nothing
  SearchDestination.Top -> Nothing

-- CR 701.24b: whether the found cards stay in the library, left out of its
-- shuffle, to be put on top after it.
putsOnTop :: SearchDestination.SearchDestination -> Bool
putsOnTop destination = case destination of
  SearchDestination.RevealThenTop -> True
  SearchDestination.Top -> True
  SearchDestination.Battlefield -> False
  SearchDestination.BattlefieldTapped -> False
  SearchDestination.RevealThenHand -> False
  SearchDestination.Exile -> False
  SearchDestination.BattlefieldAttachedOrHand -> False
  SearchDestination.BattlefieldAttached -> False
  SearchDestination.Reveal -> False
  SearchDestination.Stay -> False
  SearchDestination.Hand -> False

-- CR 701.24: whether the search's own sentence shuffles the library it read --
-- every arm but the two that leave the found cards for a later clause.
shufflesAfter :: SearchDestination.SearchDestination -> Bool
shufflesAfter destination = case destination of
  SearchDestination.Reveal -> False
  SearchDestination.Stay -> False
  SearchDestination.Battlefield -> True
  SearchDestination.BattlefieldTapped -> True
  SearchDestination.RevealThenHand -> True
  SearchDestination.Exile -> True
  SearchDestination.BattlefieldAttachedOrHand -> True
  SearchDestination.BattlefieldAttached -> True
  SearchDestination.RevealThenTop -> True
  SearchDestination.Top -> True
  SearchDestination.Hand -> True

-- Search.differentIn: the cards, in order, that keep the group apart -- each
-- shares no value on any named axis with a card kept ahead of it.
differing :: Set.Set DifferentIn.DifferentIn -> GameState -> [ObjectId] -> [ObjectId]
differing axes gs = go Set.empty
  where
    go _ [] = []
    go seen (oid : rest) = case differingValues axes gs oid of
      Just values | Set.disjoint values seen -> oid : go (values <> seen) rest
      _ -> go seen rest

-- Search.descriptions (CR 701.23h): the cards, in order, that can each answer
-- for a distinct description together with every card kept ahead of them. No
-- descriptions is no constraint. Greedy over the searcher's order is exact,
-- since the cards matchable to distinct descriptions form a transversal
-- matroid: every maximal such set is a largest one. Each check is exhaustive,
-- which the printed descriptions keep small.
matchDescriptions :: (ObjectId -> Filter.Type.Filter Keyword.Type.Keyword -> Bool) -> Seq.Seq (Filter.Type.Filter Keyword.Type.Keyword) -> [ObjectId] -> [ObjectId]
matchDescriptions fits descriptions
  | Seq.null descriptions = id
  | otherwise = go []
  where
    indexed = zip [0 :: Int ..] (Foldable.toList descriptions)
    fitting oid = [i | (i, d) <- indexed, fits oid d]
    go kept [] = reverse kept
    go kept (oid : rest)
      | assign (fmap fitting (oid : kept)) Set.empty = go (oid : kept) rest
      | otherwise = go kept rest
    assign [] _ = True
    assign (options : more) used = any (\i -> not (Set.member i used) && assign more (Set.insert i used)) options

-- CR 609.3 for Search.exactly: the most cards, up to `cap`, that `differing`
-- could keep together from `candidates` -- searched exhaustively rather than
-- greedily, since a split card's two names (CR 201.2a) can block two cards a
-- greedy pass would have kept apart. Cards with the same values are one
-- candidate, which keeps the search to the distinct ones. Exhaustive rather
-- than greedy is a REGRESSION FENCE: no board pairs a split card with a card
-- sharing one of its names, so a greedy count reddens nothing.
mostDiffering :: Set.Set DifferentIn.DifferentIn -> GameState -> Natural -> [ObjectId] -> Natural
mostDiffering axes gs cap candidates = go Set.empty 0 0 distinct
  where
    found = Maybe.mapMaybe (differingValues axes gs) candidates
    -- A card with no value at all shares none, so only the others collapse.
    distinct = ListUtils.nubOrd (filter (not . Set.null) found) <> filter Set.null found
    go seen n best rest
      | n >= cap = cap
      | n + List.genericLength rest <= best = best
      | otherwise = case rest of
          [] -> max n best
          values : more ->
            let taken = if Set.disjoint values seen then go (values <> seen) (n + 1) best more else best
             in if taken >= cap then cap else go seen n (max best taken) more

-- One card's values on Search.differentIn's axes, keyed by axis so a power never
-- meets a toughness, or Nothing for a card no group admits. Read off the CR 613
-- projection, so a split card's two names count (CR 201.2a) and a star's power
-- is its characteristic-defining ability's number (CR 208.2a, 604.3). CR 201.2b
-- demands each card HAVE a name; a card with no power or toughness shares none.
differingValues :: Set.Set DifferentIn.DifferentIn -> GameState -> ObjectId -> Maybe (Set.Set (DifferentIn.DifferentIn, Either CardName.CardName (Either Integer CardType.CardType)))
differingValues axes gs oid =
  if Set.member DifferentIn.Names axes && Set.null (Filter.names view)
    then Nothing
    else Just (foldMap valuesOf axes)
  where
    view = Projection.viewOfObject oid gs
    number axis = foldMap (Set.singleton . (,) axis . Right . Left)
    valuesOf axis = case axis of
      DifferentIn.Names -> Set.map ((,) axis . Left) (Filter.names view)
      DifferentIn.Powers -> number axis (Filter.power view)
      DifferentIn.ManaValues -> number axis (Filter.manaValue view)
      DifferentIn.Toughnesses -> number axis (Filter.toughness view)
      DifferentIn.CardTypes -> Set.map ((,) axis . Right . Right) (Filter.cardTypes view)

-- One found card's move, a member of the search's batch whose board is `asOf`
-- (Event.changeZoneInBatch).
putFound :: ObjectId -> GameState -> PlayerId -> Maybe ObjectId -> SearchDestination.SearchDestination -> ObjectId -> Game [ObjectId]
putFound resolving asOf searcher subject destination cardId = case destination of
  -- Nature's Lore's "put that card onto the battlefield", and Evolving Wilds'
  -- "put it onto the battlefield tapped": CR 110.5b's default, or the card's
  -- own rider, is the one difference between the two arms.
  SearchDestination.Battlefield -> putOntoBattlefield asOf searcher TapState.Untapped cardId
  SearchDestination.BattlefieldTapped -> putOntoBattlefield asOf searcher TapState.Tapped cardId
  -- The reveal comes FIRST, in the card's own order, and CR 701.20b makes that an
  -- order rather than decoration: revealing does not move the card. The two lines
  -- do not commute -- swapped, CR 400.7 has already ceased `cardId` and the
  -- reveal shows nothing.
  SearchDestination.RevealThenHand -> do
    Event.revealResolving resolving searcher cardId
    Foldable.toList <$> Event.changeZoneInBatchReturning asOf cardId Zone.Hand
  -- Hoarding Dragon's "exile it": the move alone, with NO Event.reveal ahead of
  -- it (CR 701.23e). Which card this instruction exiled is CR 607.2a's link,
  -- filed by recordExiledWith off the effect that ran rather than here.
  SearchDestination.Exile -> Foldable.toList <$> Event.changeZoneInBatchReturning asOf cardId Zone.Exile
  -- Auratouched Mage's "put that Aura card onto the battlefield attached to it",
  -- and Sovereigns of Lost Alara's "put it onto the battlefield attached to that
  -- creature". WHICH object "it" is, is Search.subject, resolved by the arm that
  -- ran the search -- the same value its filter asked CR 701.3a about, so the
  -- offer and the move cannot name different hosts. A subject naming no object
  -- is attachFound's undefined host.
  SearchDestination.BattlefieldAttached -> attachFound asOf searcher subject cardId
  -- The arm above with the card's second sentence added: "If this creature is
  -- still on the battlefield ... Otherwise, reveal the Aura card and put it into
  -- your hand."
  --
  -- The OUTER branch is that printed "If ... Otherwise", asked of the SUBJECT's
  -- liveness rather than of attachmentFor's Nothing. The two are different
  -- questions and the rules give them opposite answers: an Aura a LIVE host
  -- cannot legally hold stays in the library (CR 303.4i), while an Aura whose
  -- host has gone is revealed and put into its owner's hand (CR 608.2h; CR 113.7a
  -- is what keeps the ability resolving at all with its source gone). Branching
  -- on Nothing alone would send the first of those to the hand.
  --
  -- The ORDER of those two questions is a REGRESSION FENCE rather than a proven
  -- behaviour: rule 303.4i's Nothing is unreachable for the one card that reaches
  -- this arm, whose filter names Filter.CanAttachToSubject, so both readings
  -- produce the same board and swapping them reddens nothing. A card whose search
  -- filter did NOT ask rule 701.3a would be its observer.
  SearchDestination.BattlefieldAttachedOrHand -> do
    gs <- State.get
    if maybe False (\host -> Set.member host (GameState.battlefield gs)) subject
      then attachFound asOf searcher subject cardId
      else do
        -- CR 701.20b makes the order matter, for RevealThenHand's reason above:
        -- swapped, CR 400.7 has already ceased `cardId` and the reveal shows
        -- nothing. The reveal is the CARD's own instruction (CR 701.23e), which
        -- is why it is written here rather than in the searching rule.
        Event.revealResolving resolving searcher cardId
        Foldable.toList <$> Event.changeZoneInBatchReturning asOf cardId Zone.Hand
  -- Grim Reminder's "reveal it": CR 701.20b leaves the card in the library, so the
  -- object found is the object a later clause names.
  SearchDestination.Reveal -> do
    Event.revealResolving resolving searcher cardId
    pure [cardId]
  -- Doomsday's: the same, with no reveal (CR 701.23e).
  SearchDestination.Stay -> pure [cardId]
  -- Mystical Tutor's "reveal it": the card stays in the library through the
  -- Search arm's shuffle, which leaves it out, until the move to the top after it.
  SearchDestination.RevealThenTop -> do
    Event.revealResolving resolving searcher cardId
    pure [cardId]
  -- Cruel Tutor's: the same, with no reveal (CR 701.23e). The scenario
  -- visibility/cr-701-23e-private-look-cruel-tutor-puts-its-find-on-top-unrevealed
  -- is the proof.
  SearchDestination.Top -> pure [cardId]
  -- Rhystic Tutor's "put that card into your hand": the move alone, with no
  -- reveal, CR 701.23e.
  SearchDestination.Hand -> Foldable.toList <$> Event.changeZoneInBatchReturning asOf cardId Zone.Hand

-- CR 303.4's entry-attached move, shared by putFound's two attaching arms so the
-- sentence they have in common is written once.
--
-- The seed is the RECIPIENT Attach.attachmentFor produced rather than a
-- hand-built ToObject, for the reason Event.changeZoneAttaching's CR 303.4f arm
-- gives: Sba.stillLegalEnchant compares the (pool, tag) pair, so a mismatched tag
-- would have CR 704.5m bury the Aura on the next pass.
--
-- Supplying a seed at all is what keeps CR 303.4f's host prompt out of this move:
-- the effect DOES specify what the Aura will enchant, so its controller chooses
-- nothing.
--
-- CR 110.2a: it enters under the SEARCHER, the player whose effect is putting it
-- there, as putOntoBattlefield's entries do, and is judged as the searcher's
-- (Attach.entryAttachmentFor), as the search's own offer judges it. A
-- regression fence: every card in data/cards with an attaching search
-- destination (Auratouched Mage, for one) searches its controller's own zones,
-- so owner and searcher coincide.
--
-- An illegal or undefined host is CR 303.4i's "the Aura remains in its current
-- zone" for an Aura, and CR 301.5e / 303.4h's unattached entry for anything
-- else: Danitha, Benalia's Hope's Equipment with Danitha gone, which the attach
-- scenario named for CR 301.5e proves.
attachFound :: GameState -> PlayerId -> Maybe ObjectId -> ObjectId -> Game [ObjectId]
attachFound asOf searcher host cardId = do
  gs <- State.get
  case host >>= \h -> Attach.entryAttachmentFor searcher cardId (Recipient.ToObject h) gs of
    Nothing
      | Set.member Subtype.Aura (Projection.subtypesOf cardId gs) -> pure []
      | otherwise -> putOntoBattlefield asOf searcher TapState.Untapped cardId
    Just seed ->
      Foldable.toList
        <$> Event.changeZoneAttaching (Just asOf) Set.empty cardId Zone.Battlefield LibraryPosition.defaultValue (Just seed) TapState.Untapped Map.empty (Just searcher) Nothing Facing.FaceUp False CarryOver.NotCarried False Seq.empty

-- Put a found card onto the battlefield, untapped or tapped as the card says.
--
-- CR 110.2a: it enters under the SEARCHER, attachFound's reading -- Eternal
-- Dominion's "search target opponent's library ... put that card onto the
-- battlefield under your control". Parun.CastSpec's Eternal Dominion cases
-- prove it.
--
-- The tap state rides the move rather than a write after it, for CR 603.2e's
-- reason: this is the permanent ENTERING tapped, and an ability that triggers
-- when a permanent "becomes tapped" doesn't trigger if it enters in that state.
putOntoBattlefield :: GameState -> PlayerId -> TapState.TapState -> ObjectId -> Game [ObjectId]
putOntoBattlefield asOf searcher tapped cardId =
  Foldable.toList
    <$> Event.changeZoneAttaching (Just asOf) Set.empty cardId Zone.Battlefield LibraryPosition.defaultValue Nothing tapped Map.empty (Just searcher) Nothing Facing.FaceUp False CarryOver.NotCarried False Seq.empty

-- Write a whole new order back to a player's library: CR 701.22a's scry, CR
-- 701.25a's surveil and CR 701.29a's fateseal, CR 401.4's arrangement and CR
-- 701.30a's clash.
--
-- `placed` is the cards the instruction put back, wherever they land -- the
-- reordered ones of CR 701.20d / 701.20e, each of which becomes a new object if
-- it was revealed or looked at (Event.forgetShown), as a card put into the
-- library it is already in does (Event.stayPut). Parun.ClashSpec's "CR 701.20d a
-- card the clash bottoms" case is the proof.
reorderLibrary :: PlayerId -> [ObjectId] -> [ObjectId] -> GameState -> GameState
reorderLibrary pid placed order gs =
  Event.forgetAllShown placed gs {GameState.library = Map.insert pid (Seq.fromList order) (GameState.library gs)}

-- `arranger` puts the cards `cards` names back into `owner`'s library, in an
-- order they state, at the positions those cards already occupy: CR 401.4's
-- owner for a search's find, the instruction's player (CR 608.2c) for
-- Effect.ArrangeInLibrary.
--
-- The library is REWRITTEN rather than funnelled through Event.changeZone, for
-- decideScry's reason one rule over: nothing crosses a zone boundary, so CR 400.7
-- mints no new incarnation and the ids the prompt named are the ids that move;
-- CR 701.20d / 701.20e's new objects come after (reorderLibrary).
--
-- ASKED AT TWO OR MORE, which is rule 401.4's own count: one card has one
-- order, and the engine does not raise a question with a single answer. Two
-- cards are two distinct objects however alike their printings, so
-- indistinguishable here means "fewer than two cards to arrange" and nothing
-- else -- a player who knows the order of the top two cards of their library
-- can tell the two answers apart at their next draw.
--
-- The cards are taken in LIBRARY order (top first) rather than in the order the
-- reference swept them, which is what makes the answer's indices mean what
-- Prompt.ArrangeLibraryCards says they mean. A card the reference named that has
-- left the library since (CR 603.7c) is simply not among them.
arrangeInLibrary :: PlayerId -> [ObjectId] -> PlayerId -> Game ()
arrangeInLibrary arranger cards owner = do
  gs <- State.get
  let whole = Game.zoneMembers Zone.Library owner gs
      moving = filter (\oid -> List.elem oid cards) whole
  Monad.when (length moving > 1) $ do
    answer <- Game.choose (Prompt.ArrangeLibraryCards (Decide.deciderFor arranger gs) arranger moving)
    State.modify' (reorderLibrary owner moving (refill whole moving (Game.permute moving answer)))

-- Put `ordered` back at the positions `moving` occupies in `whole`, leaving
-- every other card where it was. Game.permute answers a permutation of `moving`
-- whatever it is given, so `ordered` never runs short.
refill :: [ObjectId] -> [ObjectId] -> [ObjectId] -> [ObjectId]
refill whole moving ordered =
  let step remaining oid = case (List.elem oid moving, remaining) of
        (True, next : rest) -> (rest, next)
        _ -> (remaining, oid)
   in snd (List.mapAccumL step ordered whole)

-- CR 701.22a: one player's scry DECISION, answered with the cards looked at and
-- the library order it makes -- Nothing where there was nothing to decide. A short library is looked
-- at as far as it goes; rule 701.22 states no penalty for scrying more than
-- there is. The move and the CR 701.22d event are the Scry arm's, after every
-- scryer has decided (CR 701.22c).
--
-- The library is REWRITTEN rather than funnelled through Event.changeZone:
-- nothing crosses a zone boundary, so CR 400.7 mints no new incarnation and the
-- ids the prompt named still move; CR 701.20e's new objects come after
-- (reorderLibrary). Looking mints nothing either (CR 701.20b).
--
-- Every card looked at is logged (Event.look) before the question, and where
-- none is asked: the look is the rule's, the question the engine's.
decideScry :: Integer -> PlayerId -> Game (PlayerId, Maybe ([ObjectId], [ObjectId]))
decideScry n pid = do
  gs <- State.get
  let whole = Game.zoneMembers Zone.Library pid gs
      looked = List.genericTake n whole
      beneath = List.genericDrop n whole
      -- The engine never makes the player's choice, but does not ask a question
      -- with one answer either: nothing to look at, or a single looked-at card
      -- that is the whole library. One card with more beneath it IS a decision.
      decided = case looked of
        [] -> False
        [_] -> not (null beneath)
        _ -> True
  Monad.mapM_ (Event.look pid) looked
  if decided
    then do
      answer <- Game.choose (Prompt.ChooseScry (Decide.deciderFor pid gs) pid looked)
      let (toBottom, onTop) = splitLooked looked answer
      pure (pid, Just (looked, onTop <> beneath <> toBottom))
    else pure (pid, Nothing)

-- Repair a look-and-split answer into the two groups the effect then moves: the
-- cards going AWAY from the top, and the cards staying on top in reading order.
--
-- Filtered, deduped and COMPLETED, Effect.Discard's arm's posture: a card named
-- in neither list stays on top behind the ones that were named, and a card named
-- in BOTH goes away, the first list winning. One function for all three keyword
-- actions, the repair being a question about the ANSWER.
splitLooked :: [ObjectId] -> ([ObjectId], [ObjectId]) -> ([ObjectId], [ObjectId])
splitLooked looked (away, kept) =
  let named xs = ListUtils.nubOrd (filter (\c -> List.elem c looked) xs)
      leaving = named away
      onTop = filter (\c -> List.notElem c leaving) (named kept)
      unnamed = filter (\c -> List.notElem c leaving && List.notElem c onTop) looked
   in (leaving, onTop <> unnamed)

-- CR 701.25a: one player's surveil DECISION -- decideScry's shape over a
-- different destination, answered with the library order that stays and the
-- cards bound for the graveyard. Nothing for an empty library, which is still a
-- surveil (CR 701.25d) with nothing to ask.
--
-- The ELISION is decideScry's minus its one-card case: the graveyard and the top
-- of the library are still two different places.
decideSurveil :: Integer -> PlayerId -> Game (PlayerId, Maybe ([ObjectId], [ObjectId], [ObjectId]))
decideSurveil n pid = do
  gs <- State.get
  let whole = Game.zoneMembers Zone.Library pid gs
      looked = List.genericTake n whole
      beneath = List.genericDrop n whole
  if null looked
    then pure (pid, Nothing)
    else do
      -- CR 701.25a: the cards are looked at before the split is chosen.
      Monad.mapM_ (Event.look pid) looked
      answer <- Game.choose (Prompt.ChooseSurveil (Decide.deciderFor pid gs) pid looked)
      let (toGraveyard, onTop) = splitLooked looked answer
      pure (pid, Just (onTop, beneath, toGraveyard))

-- One decided surveil's move. Half of it IS a zone change: the graveyard cards
-- go through Event.changeZoneInBatch in the order the answer named them, so the
-- first named ends up deepest (CR 404.1), an order that is the player's rather
-- than the engine's (CR 404.3) -- so the scope does not ask for it again
-- (Event.arrangedAlready).
applySurveil :: (PlayerId, Maybe ([ObjectId], [ObjectId], [ObjectId])) -> Game ()
applySurveil (pid, decision) = Monad.forM_ decision $ \(onTop, beneath, toGraveyard) -> do
  -- Order-independent: Game.removeFromZones takes each mover out of the library
  -- by identity rather than by position.
  State.modify' (reorderLibrary pid onTop (onTop <> beneath))
  -- ONE event (CR 608.2f) on ONE board, and one CR 401.4 scope for a redirect
  -- into a library.
  Event.simultaneously $ do
    before <- State.get
    arrived <- Monad.mapM (\c -> Event.changeZoneInBatchReturning before c Zone.Graveyard) toGraveyard
    State.modify' (Event.arrangedAlready (Foldable.fold arrived))

-- CR 701.29a: one player's fateseal -- decideScry's question over an opponent's
-- library.
--
-- TWO choices, both the fatesealer's and in this order: which opponent, then how
-- to split. The first is elided at one candidate (CR 102.2) and filtered rather
-- than trusted (Players.chooseOne); the library's owner is asked neither. The
-- look is the fatesealer's alone (Event.look), logged as decideScry's is.
fatesealOne :: ObjectId -> Integer -> PlayerId -> Game ()
fatesealOne source n pid = do
  gs <- State.get
  victim <- Players.chooseOne pid source Nothing (Players.offer pid gs PlayerRelation.Opponent)
  Monad.forM_ victim $ \owner -> do
    -- Re-read rather than reusing the state the opponent choice was made
    -- against: a prompt is the one place this function yields.
    chosen <- State.get
    let whole = Game.zoneMembers Zone.Library owner chosen
        looked = List.genericTake n whole
        beneath = List.genericDrop n whole
        decided = case looked of
          [] -> False
          [_] -> not (null beneath)
          _ -> True
    Monad.mapM_ (Event.look pid) looked
    Monad.when decided $ do
      answer <- Game.choose (Prompt.ChooseFateseal (Decide.deciderFor pid chosen) pid owner looked)
      let (toBottom, onTop) = splitLooked looked answer
      State.modify' (reorderLibrary owner looked (onTop <> beneath <> toBottom))

-- CR 701.30b: "Clash with an opponent" -- the controller chooses an opponent,
-- and the two of them clash (CR 701.30c). Answers 1 where the CONTROLLER won the
-- clash and 0 otherwise, which is what the opcode binds at its slot; rule 701.30
-- gives the other clashing player nothing to read.
--
-- Every decision here is a player's, in this order: which opponent (the
-- controller's, elided at one candidate by CR 102.2 and filtered rather than
-- trusted -- fatesealOne's posture), then where each clashing player puts the
-- card they revealed (their own, CR 701.30a).
--
-- The reveal is PUBLIC (CR 701.30c) and so rides Event.reveal, unlike scry's
-- private look at the same position. It is also SIMULTANEOUS, which is why every
-- card is revealed before any player is asked and why the prompt carries all of
-- them: neither player decides from a board the other has already changed, and
-- both see both cards.
--
-- The moves come after every decision, rule 701.30c's last clause ("then those
-- cards move at the same time"). Two clashing players have two libraries, so the
-- rewrites cannot interfere; the order is still the rule's rather than an
-- accident of the loop.
--
-- An EMPTY library reveals nothing and so cannot win (CR 701.30d asks for a card
-- that player revealed). CR 609.3 leaves the rest of the instruction to do what
-- it can.
clash :: ObjectId -> ObjectId -> PlayerId -> Game Natural
clash resolving source controller = do
  gs <- State.get
  chosen <- Players.chooseOne controller source Nothing (Players.offer controller gs PlayerRelation.Opponent)
  case chosen of
    -- Every other seat has left (CR 104.2a): nobody to clash with, so rule
    -- 701.30b's instruction does nothing and nobody won.
    Nothing -> pure 0
    Just opponent -> do
      -- Re-read rather than reusing the state the opponent choice was made
      -- against: a prompt is the one place this function yields.
      before <- State.get
      let clashers = filter (\pid -> List.elem pid [controller, opponent]) (Game.apnapOrder before)
          topOf pid = case Game.zoneMembers Zone.Library pid before of
            top : _ -> Just (pid, top)
            [] -> Nothing
          revealed = Maybe.mapMaybe topOf clashers
      Monad.mapM_ (uncurry (Event.revealResolving resolving)) revealed
      -- CR 701.30d: the comparison is against the cards as they were revealed,
      -- read once here rather than per decision, so no player's choice can move
      -- it. A library card has a mana value (CR 202.3), and an id nothing is
      -- filed under has none and so wins nothing.
      shown <- State.get
      let -- CR 202.3a's 0 for a card with no mana cost, which is also what
          -- Filter.manaValue answers for one; the fallback is unreachable, every
          -- id here coming out of a library.
          manaValueOf oid = Maybe.fromMaybe 0 (Filter.manaValue (Projection.viewOfObject oid shown))
          valued = fmap (Bifunctor.second manaValueOf) revealed
          others = fmap snd (filter (\(pid, _) -> pid /= controller) valued)
          won = case lookup controller valued of
            Nothing -> False
            Just value -> all (value >) others
      decisions <- case revealed of
        [] -> pure Seq.empty
        first : rest -> do
          let public = first NonEmpty.:| rest
          -- CR 101.4b: each decider is shown the decisions made before theirs.
          let decide made (pid, top) = do
                asked <- State.get
                -- The engine never makes the player's choice, but does not ask a
                -- question with one answer either: a revealed card that is the
                -- whole library is already at both ends, decideScry's elision one
                -- card over.
                let alone = length (Game.zoneMembers Zone.Library pid asked) <= 1
                    earlier = fmap (\(who, _, at) -> (who, at)) made
                position <-
                  if alone
                    then pure LibraryPosition.Top
                    else Game.choose (Prompt.ChooseClash (Decide.deciderFor pid asked) pid source top public earlier)
                pure (made Seq.|> (pid, top, position))
          Monad.foldM decide Seq.empty revealed
      -- Only a card put on the bottom is reordered: CR 701.30a's player "may
      -- then put that card on the bottom", and keeping it on top puts nothing.
      Monad.forM_ decisions $ \(pid, top, position) ->
        Monad.when (position == LibraryPosition.Bottom) $ do
          moving <- State.get
          let whole = Game.zoneMembers Zone.Library pid moving
          State.modify' (reorderLibrary pid [top] (filter (/= top) whole <> [top]))
      pure (if won then 1 else 0)

-- CR 701.44a: one permanent's explore.
--
-- The controller comes from LAST KNOWN INFORMATION (CR 701.44c), so a permanent
-- killed while the instruction was on the stack still explores; its counter then
-- lands on nothing while the reveal and the choice still happen, which is rule
-- 701.44b's "even if some or all of those actions were impossible".
--
-- The reveal is PUBLIC (CR 701.20a) and so rides Event.reveal, unlike scry's
-- private look at the same position.
--
-- "If a land card is revealed" is asked of the revealed card's own CR 613
-- projection: rule 613.1 starts from the actual object and names no zone, so a
-- library card is folded exactly as a permanent is, and a layer-4 type change
-- (CR 613.1d) reaches it there. An id nothing is filed under projects no card
-- types, so it is no land card -- the answer the printed face gave.
exploreOne :: ObjectId -> ObjectId -> Game ()
exploreOne resolving oid = do
  -- CR 122.6 through the one counter funnel, so a CR 614.1 counter replacement
  -- (Hardened Scales) gets its opportunity against this placement too.
  let grow pid = Monad.void (Event.putCounters (CounterCause.ByEffect pid) oid CounterKind.PlusOnePlusOne 1)
  gs <- State.get
  case Projection.controllerWithLastKnown oid gs of
    -- An id nothing was ever filed under: nobody explores and nothing happens.
    Nothing -> pure ()
    Just pid -> do
      case Game.zoneMembers Zone.Library pid gs of
        [] -> grow pid
        top : _ -> do
          Event.revealResolving resolving pid top
          after <- State.get
          let isLand = Set.member CardType.Land (Filter.cardTypes (Projection.viewOfObject top after))
          if isLand
            then Event.changeZone top Zone.Hand
            else do
              grow pid
              asked <- State.get
              decision <- Game.choose (Prompt.ChooseExplore (Decide.deciderFor pid asked) pid oid top)
              Monad.when (decision == OptionalDecision.Exercises) (Event.changeZone top Zone.Graveyard)
      -- CR 701.44b: the permanent explores once the whole of rule 701.44a is
      -- done, so this comes after every branch above. Inside the Just, since an
      -- id nobody ever controlled explores nothing; but not inside the library
      -- case, that rule firing even when the actions were impossible.
      State.modify' (Event.recordEvent (GameEvent.PermanentActed (PermanentActed.MkPermanentActed PermanentAction.Explore oid)))

-- CR 701.50d: one permanent's connive N. Rule 701.50a's bare connive is this
-- with N of one, so there is no second road.
--
-- The controller comes from last known information (CR 701.50b), so a permanent
-- gone before the instruction resolves still connives: its controller draws and
-- discards, and the counters land on nothing -- the id is gone (CR 400.7), so
-- putCounters places none.
--
-- CR 701.50e: connive 0 is not a connive. No draw, no discard, no counter, and
-- none of CR 701.50f's event below. Parun.CardTriggerSpec's Spymaster's Vault
-- group proves it.
--
-- "Nonland" is asked of each card the discard funnel MINTED, through its CR 613
-- projection, exploreOne's reading: the hand incarnation is gone by then, and a
-- double-faced card in a graveyard has only its front face's characteristics
-- (CR 712.8a).
conniveOne :: Natural -> ObjectId -> Game ()
conniveOne n oid = Monad.when (n > 0) $ do
  gs <- State.get
  Monad.forM_ (Projection.controllerWithLastKnown oid gs) $ \pid -> do
    -- CR 121.2a: the N-card draw is one replaceable instruction, settled before
    -- any of CR 121.2's individual draws -- Effect.Draw's arm, line for line.
    outcome <- Event.applyReplacements (ProposedEvent.WouldPerform PlayerInstruction.DrawCards Nothing pid n)
    Monad.forM_ (outcome >>= Replacement.asPerformed PlayerInstruction.DrawCards) $ \(drawer, settled) ->
      Monad.replicateM_ (Natural.toIntSaturating settled) (Event.drawCard drawer)
    drawn <- State.get
    let held = Game.zoneMembers Zone.Hand pid drawn
    -- The discard is N however many cards the draw actually delivered (CR
    -- 701.50d), and CR 609.3 clamps it to the hand.
    chosen <-
      if n >= Natural.length held
        -- CR 609.3: discarding the whole hand is "as much as possible," so it is
        -- forced -- no choice, so no prompt.
        then pure held
        else do
          -- CR 701.9b: the discarding player chooses which cards. Filtered,
          -- completed and deduplicated, Effect.Discard's posture; this branch is
          -- reached only when the hand is LARGER than N, so every omitted card is
          -- one the player could have discarded.
          answer <- Game.choose (Prompt.ChooseDiscard (Decide.deciderFor pid drawn) pid held n)
          let valid = ListUtils.nubOrd (filter (\c -> List.elem c held) answer)
              filler = filter (\c -> List.notElem c valid) held
          pure (List.genericTake n (valid <> filler))
    -- One event group: CR 701.50d discards the N cards as one action.
    cause <- State.gets Event.resolvingDiscardCause
    moved <- Event.simultaneously (fmap (concatMap Foldable.toList) (Monad.mapM (Event.discardReturning cause pid) chosen))
    after <- State.get
    let nonland c = not (Set.member CardType.Land (Filter.cardTypes (Projection.viewOfObject c after)))
        grown = Natural.length (filter nonland moved)
    -- CR 701.50d: one counter per nonland card discarded, CR 122.6 through the
    -- one counter funnel, as exploreOne's grow.
    Monad.when (grown > 0) $
      Monad.void (Event.putCounters (CounterCause.ByEffect pid) oid CounterKind.PlusOnePlusOne grown)
    -- CR 701.50f: the permanent connives once the whole of rule 701.50d is done,
    -- so this comes after every step above and fires even where they were
    -- impossible -- exploreOne's CR 701.44b line. Inside the Just, since an id
    -- nobody ever controlled connives nothing; CR 701.50e's zero never reaches
    -- here, the guard above having returned.
    State.modify' (Event.recordEvent (GameEvent.PermanentActed (PermanentActed.MkPermanentActed PermanentAction.Connive oid)))

-- CR 702.26e: the objects a resolving effect that changes characteristics or
-- control freezes (CR 611.2c), less every phased-out permanent -- even one it
-- names specifically, as a `self` group slot does. ModifyTarget's arm and
-- installControl are the callers. Parun.PhasingSpec's two "CR 702.26e a
-- phased-out permanent is left out of a resolving ..." cases are the proof, one
-- per caller.
frozenAffected :: GameState -> [ObjectId] -> [ObjectId]
frozenAffected gs = filter (not . (`Phasing.isPhasedOut` gs))

-- CR 613.1b / 611.2c: install a layer-2 control effect giving `recipient` the
-- objects `ref` names, for `duration` -- GainControl's arm.
installControl :: Map.Map SlotName (Set Recipient) -> ObjectId -> PlayerId -> ObjectId -> PlayerId -> Duration.Duration -> ObjectRef.ObjectRef -> GameState -> GameState
installControl legal resolving controller source recipient duration ref gs =
  -- Enumerated ONCE by the shared sweep; a player recipient, an illegal slot
  -- (CR 608.2b) and a set that matched nothing all change nothing.
  case frozenAffected gs (objectRefObjects legal resolving controller source gs ref) of
    [] -> gs
    targets
      -- CR 800.4b: an object doesn't change to the control of a player who has
      -- left the game. A recipient read relative to `controller` is baked at
      -- trigger time (CR 113.8), and CR 800.4a's exile clause is not a state-based
      -- action, so it has already run and does not run again; without this guard
      -- the permanent would sit on the battlefield controlled by a player not in
      -- the game.
      | List.notElem recipient (Game.stillPlaying gs) -> gs
      -- CR 611.2b's condition is baked against `legal` rather than `chosen`, so a
      -- slot CR 608.2b has emptied never starts the duration.
      | otherwise -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
          -- CR 611.2b: the duration never started, so nothing is stored and
          -- control never changed.
          Nothing -> gs
          Just expiry ->
            -- CR 613.1b / 611.2c: the new controller is baked in now. CR 302.6
            -- re-Sicks it, unless control does not actually move, which is why
            -- the question is asked PER OBJECT and against the PROJECTED
            -- controller rather than against Object.owner.
            --
            -- CR 611.2c: one stored effect over the frozen id set.
            let (ts, gs1) = Game.freshTimestamp gs
                eff =
                  ContinuousEffect.MkContinuousEffect
                    { ContinuousEffect.source = source,
                      ContinuousEffect.timestamp = ts,
                      ContinuousEffect.expiry = expiry,
                      ContinuousEffect.modification = Modification.SetController recipient,
                      ContinuousEffect.affected = Affected.TheseObjects (Set.fromList targets)
                    }
                sicken o = o {Object.sickness = Sickness.Sick}
                moved = filter (\oid -> Projection.controllerOf oid gs /= Just recipient) targets
             in gs1
                  { GameState.continuousEffects = eff : GameState.continuousEffects gs1,
                    GameState.objects = foldr (Map.adjust sicken) (GameState.objects gs1) moved
                  }

-- CR 608.2d: the seats a branch's own questions are offered to. A clause naming
-- no sibling keeps every seat its reference named; one that names a sibling
-- keeps only the seats that announced it, in the APNAP order the caller already
-- imposed.
announcedOnly :: Maybe (Set PlayerId) -> [PlayerId] -> [PlayerId]
announcedOnly = maybe id (\winners -> filter (`Set.member` winners))

-- Which players a CR 118.12 branch selects from the offer's answers, off the
-- classification a card states -- never off what the payment DID. IfPaid and
-- IfNotPaid are per player; IfNonePaid is one answer for the table, selecting
-- every offered player when none paid and nobody when any did.
branchSelects :: PayBranch.PayBranch -> Map.Map PlayerId Bool -> Set PlayerId
branchSelects branch asked = case branch of
  PayBranch.IfPaid -> Map.keysSet (Map.filter id asked)
  PayBranch.IfNotPaid -> Map.keysSet (Map.filter not asked)
  PayBranch.IfNonePaid -> if or asked then Set.empty else Map.keysSet asked

-- CR 101.4b: an answer as a later payer is told it -- Pays exactly when the
-- payment went through, so a payer who could not pay (CR 118.3), had left (CR
-- 800.4f) or repeated a payment that failed (payAgain) reads as having
-- declined.
paymentDecisionOf :: Maybe a -> PaymentDecision.PaymentDecision
paymentDecisionOf paid = if Maybe.isJust paid then PaymentDecision.Pays else PaymentDecision.Declines

-- CR 733.1 / 118.12a: what follows a payment `agreed` to and answered as it
-- was (payGateCost's record). A paid one stands. A failed one is reversed, which
-- returns the payer to the choice, so `again` asks it once more. The same
-- option paid the same way failing a second time stands, read as unpaid, as
-- Combat.attemptBlockDeclaration keeps a repeated illegal declaration.
payAgain :: (Ord k) => Set k -> k -> Maybe a -> (Set k -> Game (Maybe a)) -> Game (Maybe a)
payAgain failed agreed paid again = case paid of
  Just _ -> pure paid
  Nothing
    | Set.member agreed failed -> pure Nothing
    | otherwise -> again (Set.insert agreed failed)

-- The costs one offer of this gate may be paid with, one per option in printed
-- order (PayGate.cost), with the slot map their components read: payGatePaidBy's
-- CR 107.3 X, CR 118.6 description and "for each" multiplier, applied to each.
gateCostOf :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PayGate.PayGate -> GameState -> (Map.Map SlotName (Set Recipient), NonEmpty.NonEmpty (Cost.Type.Cost Keyword.Type.Keyword))
gateCostOf resolving source controller legal gate gs =
  let evaluated quantity =
        let viewOf = effectViewOf resolving source legal gs
            context = effectContext gs resolving controller source legal (slotBindings resolving gs)
         in maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source quantity)
      multiplier = maybe 1 evaluated (PayGate.perEach gate)
      -- CR 107.3f's X, chosen during resolution, or else CR 107.3a's announced one.
      chosenX = maybe (announcedXOn resolving gs) evaluated (PayGate.x gate)
      costs = fmap (Cost.repeated multiplier . Cost.substituteX chosenX) (describedCosts resolving controller source legal gs gate)
      -- effectContext's slot map, so a component's criterion reads what every
      -- other filter of this resolution reads -- CR 608.2b's legal targets, the
      -- reserved cost slots among them (Binding.discardedCard), and the groups.
      -- Parun.ConjureSpec's Calim's Breath cases prove it.
      slots = Binding.recipientsBySlot legal (slotBindings resolving gs)
   in (slots, costs)

-- CR 118.3 / 800.4f for one seat, before any offer: could this payer pay any
-- of this gate's options against the board as it stands? Parun.Engine.Resolve.chosenBranch
-- asks it per announcing seat, CR 608.2d's "can't choose an option that's ...
-- impossible" being a question about the player choosing.
gateAffordable :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerId -> PayGate.PayGate -> GameState -> Bool
gateAffordable resolving source controller legal payer gate gs =
  let (slots, options) = gateCostOf resolving source controller legal gate gs
   in elem payer (Game.stillPlaying gs) && any (\cost -> Cost.canPayReading slots PaymentSubject.ForNeither payer source cost gs) options

-- CR 118.12a's question, before anything is paid: does this payer take the
-- offer, and with which option? The option agreed to, Nothing for none. CR
-- 800.4f and CR 118.3 first, as payGatePaidBy says. `owed` is what the payer has
-- already agreed to pay alongside it, so affordability is of the TOTAL (CR
-- 118.3, and Killing Wave's ruling "you can't pay more life than you have") --
-- Nothing for a clause's single offer.
--
-- Of several options (Torment of Venom's "sacrifice ... or discard a card"),
-- only the payable ones are offered (CR 118.3), and the payer picks among them
-- with Prompt.ChooseCost, asked only where two or more are payable; an answer
-- outside them pays nothing. Then Prompt.ChooseToPay over the option picked, so
-- an optional cost can still be declined. Proved by Parun.ResolveSpec's "CR
-- 118.12 a choice of costs" group.
payGateAgreed :: ObjectId -> ObjectId -> PayOffer.PayOffer -> Seq.Seq (PlayerId, PaymentDecision.PaymentDecision) -> PlayerId -> PayGate.PayGate -> Map.Map SlotName (Set Recipient) -> Maybe (Cost.Type.Cost Keyword.Type.Keyword) -> NonEmpty.NonEmpty (Cost.Type.Cost Keyword.Type.Keyword) -> Game (Maybe (Cost.Type.Cost Keyword.Type.Keyword))
payGateAgreed resolving source offer earlier payer gate slots owed options = do
  gs <- State.get
  let total cost = maybe cost (`Cost.plus` cost) owed
      payable = filter (\cost -> Cost.canPayReading slots PaymentSubject.ForNeither payer source (total cost) gs) (NonEmpty.toList options)
  if notElem payer (Game.stillPlaying gs)
    then pure Nothing
    else do
      picked <- case payable of
        [] -> pure Nothing
        [only] -> pure (Just only)
        _ -> do
          answer <- Game.choose (Prompt.ChooseCost (Decide.deciderFor payer gs) payer resolving (fmap Cost.untagged payable))
          pure (List.find ((== answer) . Cost.untagged) payable)
      case picked of
        Nothing -> pure Nothing
        Just cost -> do
          decision <- case PayGate.obligation gate of
            PayObligation.Mandatory -> pure PaymentDecision.Pays
            PayObligation.Optional -> Game.choose (Prompt.ChooseToPay (Decide.deciderFor payer gs) payer resolving offer cost earlier)
          pure (if decision == PaymentDecision.Pays then Just cost else Nothing)

-- CR 608.2c / 608.2h: the slots CR 118.12's payments bound, folded onto the
-- RESOLVING object once every payer of one offer has paid, so a later
-- instruction of the same resolution reads "the sacrificed creature" (Feed the
-- Pack). Parun.Engine.Cast's and Parun.Engine.Activate's fold, one carrier over.
--
-- Several payers' slots are MERGED (Binding.mergePaid), never left-biased: two
-- players who each sacrificed a creature to one offer bound two, which
-- Binding.onlyOne declines to read as "the" one rather than answering with
-- whichever paid last. Across offers the slot is REPLACED (setPaid): a later
-- "the sacrificed creature" names the later offer's sacrifice, not an earlier
-- payment of the same resolution.
--
-- Only onto a STACK object: CR 605.3b's mana ability has none, and
-- performManaPayGate's `source` standing in for one is a permanent, whose own
-- bindings this must not write.
--
-- Proved by the Feed the Pack and Rhovanion Rampager scenarios under
-- data/scenarios/resolve/. The merge, loopOffers' fold and the stack-only guard
-- are REGRESSION FENCES: no card in data/cards/ reads a slot after a
-- several-payer or per-member offer, or pays a slot-binding cost in a mana
-- ability.
foldPaid :: ObjectId -> Map.Map SlotName Binding.Type.Binding -> GameState -> GameState
foldPaid resolving bound gs
  | Map.null bound = gs
  | otherwise =
      let put obj
            | Object.zone obj == Zone.Stack = obj {Object.bindings = Binding.setPaid bound (Object.bindings obj)}
            | otherwise = obj
       in gs {GameState.objects = Map.adjust put resolving (GameState.objects gs)}

-- CR 118.6: the gate's cost with its mana part DESCRIBED rather than printed --
-- Flash's "unless you pay its mana cost reduced by {2}", where the mana part is
-- the mana cost of the creature its first clause put onto the battlefield, less
-- the {2} (CR 118.7). The gate's own cost unchanged when it describes nothing,
-- which is every other gate in the pool.
--
-- Settled HERE, as the gate is offered, because there is no earlier moment: CR
-- 118.12 puts the payment at resolution, and the object the basis names is one
-- an earlier clause of this same resolution bound (CR 608.2c). Ahead of
-- `substituteX` in the caller, so an {X} in the derived mana cost is
-- substituted by the same announcement a stated one's is -- CR 107.3h fixes
-- that value at 0 for every object but a spell on the stack, and a basis names
-- a PERMANENT on every printing of this family.
--
-- Through the PROJECTION (`effectViewOf`), never the printed card: CR 706.2
-- makes a mana cost a copiable value, so a permanent that is a copy of another
-- card owes the copied cost, and a permanent whose mana cost a CR 613 effect
-- changed owes the changed one.
--
-- Nothing where the slot names no object or several, and Nothing where the
-- object has no mana cost (CR 202.1b) -- CR 118.6's own second sentence, "an
-- ability can also have an unpayable cost if its cost is based on the mana cost
-- of an object with no mana cost", which Cost.canPay then refuses. A slot
-- naming several names no one cost, which is why Parun.Engine.Resolve.Slots.modeSlots
-- reports the read at SlotArity.One.
--
-- The stated COMPONENTS survive: what a basis supplies is the mana part alone,
-- and a card stating both pays both. None in the pool does.
describedCosts :: ObjectId -> PlayerId -> ObjectId -> Map.Map SlotName (Set Recipient) -> GameState -> PayGate.PayGate -> NonEmpty.NonEmpty (Cost.Type.Cost Keyword.Type.Keyword)
describedCosts resolving controller source legal gs gate = case PayGate.basis gate of
  Nothing -> CostChoice.unwrap (PayGate.cost gate)
  Just basis ->
    let -- The gate's own `legal` is the START-of-resolution targets (CR 608.2b,
        -- payGateAdmits' caller), which is not where a slot an EARLIER CLAUSE
        -- defined lives: CR 400.7j's binding is written to the resolving object
        -- as that clause runs, and Flash's "it" is one of those. Both halves,
        -- the validated targets winning where a card names a slot that is both.
        bound = Map.union legal (Binding.targetsOf (slotBindings resolving gs))
        described = case objectRefObjects bound resolving controller source gs (ObjectRef.InSlot (CostBasis.slot basis)) of
          [oid] -> Filter.manaCost =<< effectViewOf resolving source bound gs oid
          _ -> Nothing
     in fmap (\option -> option {Cost.Type.mana = fmap (Cost.reducedManaCost (CostBasis.reducedBy basis)) described}) (CostChoice.unwrap (PayGate.cost gate))

-- CR 118.4 / CR 107.3a: the value of X in a cost paid during resolution. NOT a
-- choice the payer makes -- CR 107.3a fixes it at the value the object's own
-- controller announced at CR 601.2b, and CR 107.3i gives every instance of X on
-- that object that one value -- so Clash of Wills' "unless its controller pays
-- {X}" charges the X its caster paid for, and nobody is prompted here.
--
-- Read off the object CR 601.2b announced ON: the SPELL (Cast.castSpell stamps
-- the new incarnation) or the ABILITY (Activate.activateAbility stamps the
-- ability object), which is `resolving` in both cases and never `source` --
-- Quantity.evaluateFor's InSlot arm says the same about the same binding.
--
-- Zero when nothing was announced. A card-authored gate printing {X} either
-- reads an {X} its spell or activation declares, or an X inherited under CR
-- 107.3m, or names its own (PayGate.x, CR 107.3f) and never reaches here --
-- Parun.CardSpec's "reads X declares X" lints and its "CR 107.3f" trigger
-- sweep hold card data to that, so this is a totality guard for a card. A gate MINTED by a
-- keyword resolves on a triggered ability that announced nothing, and reads 0
-- here.
--
-- CR 702.21b's ward {X} is the value this reader is NOT: determined as the
-- ability resolves rather than announced, it rides PayGate.perEach instead
-- (Parun.Types.Ward.perEach, Parun.Engine.Keyword.ward).
announcedXOn :: ObjectId -> GameState -> Natural
announcedXOn oid gs =
  Maybe.fromMaybe
    0
    (Game.lookupObject oid gs >>= Binding.amountOf Binding.variableX . Object.bindings)
