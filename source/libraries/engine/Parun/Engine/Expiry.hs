-- CR 611.2: the life cycle of a stored effect's duration. The ONLY module that
-- may case on Parun.Types.Expiry -- the standing Parun.Engine.Resolve has over
-- Effect and Parun.Engine.Projection over Modification. It owns the
-- transformation from the PRINTED Duration to the STORED Expiry (`arm`) and
-- every sweep that ends one, over the carriers traverseExpiries names, which
-- share one expiry vocabulary and so share one sweep.
--
-- Carriers that hold no Expiry at all are swept here anyway: rule 701.35a fixes
-- a detain's duration, rule 701.15a a goad's and rule 702.171b a saddle's, so
-- each is a field on an object rather than a vocabulary of durations, and one
-- sweep alone reaches it. See clearedDetentions, clearedGoads and
-- clearedSaddles.
--
-- CR 800.4c is NOT asked here, and deliberately: a sweep that ends a
-- control-changing effect leaves the object reading as controlled by its CR
-- 110.2 default controller, and Parun.Engine.Departure.exileOrphanedByEndedControl
-- answers the rule off that board at the next CR 117.5 settle. Nothing can
-- observe the gap, the cleanup step included (CR 514.3a).
module Parun.Engine.Expiry where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Functor.Const as Const
import qualified Data.Functor.Identity as Identity
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Condition as Condition
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Players as Players
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as View
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActiveAttackProhibition as ActiveAttackProhibition
import qualified Parun.Types.ActiveAttackRequirement as ActiveAttackRequirement
import qualified Parun.Types.ActiveBlockRequirement as ActiveBlockRequirement
import qualified Parun.Types.ActiveCopy as ActiveCopy
import qualified Parun.Types.ActiveEvasion as ActiveEvasion
import qualified Parun.Types.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Parun.Types.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Types.AfterTurn as AfterTurn
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.CopyCoverage as CopyCoverage
import qualified Parun.Types.DelayedTrigger as DelayedTrigger
import qualified Parun.Types.Designation as Designation
import Parun.Types.Duration (Duration)
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.EventExpiry as EventExpiry
import qualified Parun.Types.ExilePlayPermission as ExilePlayPermission
import Parun.Types.Expiry (Expiry)
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ExtraTurn as ExtraTurn
import Parun.Types.Game (Game)
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.IgnoredAbility as IgnoredAbility
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.PaidExpiry as PaidExpiry
import qualified Parun.Types.Phase as Phase
import Parun.Types.PhaseSelector (PhaseSelector)
import qualified Parun.Types.PhaseSelector as PhaseSelector
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerRef as PlayerRef
import Parun.Types.Recipient (Recipient)
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.While as While

-- CR 611.2: the moment a duration BEGINS. `controller` is the effect's
-- controller -- CR 109.5's "you" -- and `source` is the object the effect comes
-- from. Nothing means the duration never started, so per CR 611.2b the effect
-- does nothing and is never stored at all.
--
-- `targets` is the resolution's binding environment -- CR 601.2c's chosen
-- recipients, already filtered by CR 608.2b. Projected to the seats it names
-- (Binding.playersIn) it is what a CR 611.2b condition saying "that player" is
-- baked against, HERE and only here -- see the ForAsLongAs arm. It is also what
-- UntilEndOfNextTurnOf's reference is sampled from, which is why the whole
-- environment is passed rather than the seats alone: that arm may name a slot
-- holding an OBJECT. Empty for a caller with no resolution behind it, whose
-- durations name no slot.
--
-- `acquisition` says which acquisition's choices a slot's object is read under
-- (CR 607.5): Game.readingAcquisition for a resolution, so an ability whose
-- source has since become a copy of something else still reads the choice its
-- own pair made (CR 607.2d); Game.acquisitionOf otherwise. Proved by
-- data/scenarios/copy/cr-607-5-a-grudgekeeper-ability-still-times-its-window-by-the-chosen-player-after-mirrorweave.json.
--
-- CR 611.2b's second sentence is vacuous here: this runs once, at the point the
-- effect would be stored, and no opcode both ends and restarts a condition
-- mid-resolution.
arm :: (GameState -> ObjectId -> Acquisition.Acquisition) -> Map.Map SlotName (Set.Set Recipient) -> PlayerId -> ObjectId -> Duration -> GameState -> Maybe Expiry
arm acquisition targets controller source duration gs = case duration of
  Duration.UntilEndOfTurn -> Just Expiry.AtCleanup
  Duration.Indefinite -> Just Expiry.Never
  -- Alchemy's "perpetually": Never's lifetime under an arm a zone change can
  -- find (Parun.Engine.Event.perpetuate).
  Duration.Perpetual -> Just Expiry.Perpetual
  Duration.UntilYourNextTurn -> Just (Expiry.AtTurnOf controller)
  -- CR 611.2a: the arm above's seat, ended as the named step of that
  -- player's turn next begins. A duration armed during that very step outlives
  -- it: the step has already begun, so only a later beginning ends it.
  Duration.UntilYourNextStep step -> Just (Expiry.AtStepOf (StepBegan.MkStepBegan step controller))
  -- CR 611.2a: "until the end of your next turn". Two samples, both taken here
  -- and neither ever rewritten: the controller (CR 109.5's "you", as above) and
  -- the turn this duration began on. dropAtCleanup ends it at the first turn of
  -- the controller's numbered ABOVE that one -- so a duration that began during
  -- their own turn survives that turn's cleanup, which is the whole difference
  -- between this arm and the one above.
  Duration.UntilEndOfYourNextTurn ->
    Just (Expiry.AtEndOfTurnOf (AfterTurn.MkAfterTurn controller (GameState.turnNumber gs)))
  -- CR 611.2a: the arm above's window with the seat SAMPLED from a reference
  -- instead of taken from CR 109.5's "you". The turn number is sampled the same
  -- way and for the same reason, so the two arms share dropAtCleanup's reading
  -- whole and differ only in whose turn is counted.
  --
  -- Nothing where the reference names nobody, which is CR 611.2b's "the duration
  -- never started": a slot emptied by CR 608.2b holds no recipient, and an effect
  -- whose window cannot begin is not stored. Silent, deliberately -- the
  -- alternative is arming against some other seat.
  Duration.UntilEndOfNextTurnOf ref ->
    fmap
      (\pid -> Expiry.AtEndOfTurnOf (AfterTurn.MkAfterTurn pid (GameState.turnNumber gs)))
      (seatOf (acquisition gs) targets controller gs ref)
  -- CR 611.2a: the same seat and the same turn number as the arm above, under an
  -- arm that also states a BEGINNING. Sampled through seatOf for that arm's
  -- reasons, and Nothing where the reference names nobody for that arm's reason
  -- too -- a window that cannot begin stores nothing.
  --
  -- The controller of a bound object still in the game is NOT sampled: its
  -- seat is read live and pinned once its controller's declare attackers step
  -- has passed (pinAfterDeclareAttackers), so a control change before then
  -- moves the window (CR 611.2a).
  Duration.DuringNextTurnOf ref -> case ref of
    PlayerRef.HolderOfBound Holder.Controller Hop.Itself slot
      | Just oid <- Map.lookup slot (Binding.objectsIn targets),
        Maybe.isJust (Game.lookupObject oid gs) ->
          Just (Expiry.DuringTurnOfControllerOf (AfterObjectTurn.MkAfterObjectTurn oid (GameState.turnNumber gs)))
    _ ->
      fmap
        (\pid -> Expiry.DuringTurnOf (AfterTurn.MkAfterTurn pid (GameState.turnNumber gs)))
        (seatOf (acquisition gs) targets controller gs ref)
  -- CR 611.2a / 502.3: the arm above's seat, sampled the same way, with the
  -- untap step for the window. No turn is sampled: no player receives priority
  -- during an untap step (CR 502.4), so nothing arms this inside the window it
  -- names, and the first of that player's untap steps to begin is the next one.
  Duration.DuringNextUntapStepOf ref -> fmap Expiry.DuringUntapStepOf (seatOf (acquisition gs) targets controller gs ref)
  -- CR 611.2a: the arm above's window with the seat taken from CR 109.5's "you",
  -- as UntilYourNextTurn takes it. Never Nothing -- a controller is always a
  -- seat, so this window always begins.
  Duration.DuringYourNextTurn ->
    Just (Expiry.DuringTurnOf (AfterTurn.MkAfterTurn controller (GameState.turnNumber gs)))
  -- CR 611.2a / 500.7: the extra turn this resolution created, named by its
  -- creation stamp as Onset.FromThatExtraTurn names it (Turn.thatExtraTurn).
  -- Nothing where no such turn is pending: the window cannot begin, so per CR
  -- 611.2b's reading above nothing is stored.
  Duration.DuringThatExtraTurn -> fmap Expiry.DuringExtraTurn (Turn.thatExtraTurn source controller gs)
  -- BAKED, and stored baked: the condition outlives the resolution that stored
  -- it, and sweepConditional below re-reads it off the effect's
  -- SOURCE, whose bindings never held the resolution's slots. An InSlot left
  -- standing would answer Nothing there, Condition.holds would collapse that to
  -- False, and the effect would silently end at the first settle -- or, for an
  -- ability, never start at all, since the same unresolvable reference is read
  -- one line below.
  Duration.ForAsLongAs cond ->
    let baked = Condition.bakeBound targets cond
     in if Condition.holds (Projection.fullView gs) (Projection.sourceContext gs (Just controller) source) gs source baked
          then Just (Expiry.While (While.MkWhile controller baked))
          else Nothing
  -- CR 500.5a / 511.2: "until end of combat" is the end of the combat PHASE, so
  -- the stored window is PhaseSelector.CombatPhase and never the end of combat
  -- step. Naming the phase is the whole of the arming: unlike UntilYourNextTurn
  -- there is nothing about the game to bake in, because every producer arms it
  -- during combat and the sweep ends the effect at the first combat phase whose
  -- end it sees.
  Duration.UntilEndOfCombat -> Just (Expiry.AtEndOf PhaseSelector.CombatPhase)
  -- CR 500.5a / 611.2a: UntilEndOfYourNextTurn's two samples, so the combat
  -- phase that ends it is one of the controller's LATER turns and never the
  -- current one's.
  Duration.UntilEndOfCombatOnYourNextTurn ->
    Just (Expiry.AtEndOfCombatOn (AfterTurn.MkAfterTurn controller (GameState.turnNumber gs)))
  -- CR 116.2c: nothing about the game's clock is baked in, because no window of
  -- the turn ends this -- the PRICE is carried through unchanged so the offer
  -- below can quote it and the payment charge it. The SEAT is baked, as
  -- UntilYourNextTurn's is: `controller` here is the resolving object's
  -- controller, stamped at the ability's creation (CR 602.2a, Resolve's
  -- effectController), which is exactly CR 109.5's "the player who activated the
  -- ability" -- and unlike that rule's static-ability sentence it must not follow
  -- the source's control afterwards.
  Duration.UntilPaid cost -> Just (Expiry.WhenPaid (PaidExpiry.MkPaidExpiry controller cost))
  -- CR 611.2a: nothing about the game's clock or a payment is baked in --
  -- Parun.Engine.PlayerEffect.spentByCast/spentByLandPlay are what end this
  -- early, matching the stored effect's own Filter against whatever was just
  -- cast or played, and a delayed trigger's own firing ends it (`firesOnce`).
  -- Those read only a player effect on PlayerEffect.castUse's axes or a
  -- delayed trigger, so Parun.EffectLintSpec refuses the duration on every
  -- other carrier and axis.
  Duration.UntilUsed -> Just Expiry.WhenUsed
  -- CR 611.2a: the seat CR 109.5 reads a cast's criterion from is baked, as
  -- UntilPaid's is, and so is any seat the criterion names by slot
  -- (Parun.Engine.Filter.bakeBound), since the sweep has no resolution to read
  -- one off. Parun.Engine.Resolve.Arms.Damage's TurnFaceDown arm and
  -- Parun.Engine.Cast's CR 601.2i event sweep the moments that end it.
  Duration.UntilEvent event ->
    Just
      ( Expiry.OnEvent
          ( EventExpiry.MkEventExpiry controller $ case event of
              DurationEvent.SourceTurnedFaceDown -> event
              DurationEvent.Planeswalked -> event
              DurationEvent.SpellCast criterion -> DurationEvent.SpellCast (Filter.bakeBound (Binding.playersIn targets) Map.empty Map.empty criterion)
          )
      )

-- The ONE seat a Duration.UntilEndOfNextTurnOf or DuringNextTurnOf reference
-- names, sampled as the window begins. One stored row names one turn, so a
-- reference naming several seats arms nothing; no printing states such a window
-- (Scryfall o:"each opponent's next turn", o:"opponents' next turns",
-- 2026-09-25, no hit).
--
-- Parun.Engine.Players' reading over the resolution's slots, CR 608.2h's last
-- known information answering a controller or owner: Suspend Aggression's "its
-- owner" is asked of a card already in exile, which CR 108.4 leaves with no
-- controller, and CR 108.4a then answers with the owner.
--
-- Not cut to the controller's range: a window names a turn and affects nobody,
-- which is what CR 801.10 cuts.
--
-- Candidate names nobody here: it is the member a per-player fold has reached,
-- and the one fold that states such a window substitutes the member as Specific
-- before arming (perSeat).
seatOf :: (ObjectId -> Acquisition.Acquisition) -> Map.Map SlotName (Set.Set Recipient) -> PlayerId -> GameState -> PlayerRef.PlayerRef -> Maybe PlayerId
seatOf acquisition targets controller gs ref =
  let given = Players.resolution (`Projection.controllerWithLastKnown` gs) (`Game.ownerWithLastKnown` gs) acquisition targets (Just controller) controller gs
   in case Players.named given {Players.reaches = const True} gs ref of
        Just [pid] -> Just pid
        _ -> Nothing

-- CR 611.2a: "each opponent can't cast instant or sorcery spells during THAT
-- PLAYER's next turn" (Sphinx's Decree) -- a window whose seat is the member a
-- per-player fold has reached, so one resolution states one window per member.
-- Just the duration with that member baked in as PlayerRef.Specific, for a
-- duration naming the fold's Candidate; Nothing for every other duration, whose
-- window is the same for every member. Parun.Engine.Resolve.Effect's
-- Effect.AffectPlayers arm is the fold.
perSeat :: Duration -> Maybe (PlayerId -> Duration)
perSeat duration = case duration of
  Duration.UntilEndOfNextTurnOf PlayerRef.Candidate -> Just (Duration.UntilEndOfNextTurnOf . PlayerRef.Specific)
  Duration.UntilEndOfNextTurnOf _ -> Nothing
  Duration.DuringNextTurnOf PlayerRef.Candidate -> Just (Duration.DuringNextTurnOf . PlayerRef.Specific)
  Duration.DuringNextTurnOf _ -> Nothing
  Duration.DuringNextUntapStepOf PlayerRef.Candidate -> Just (Duration.DuringNextUntapStepOf . PlayerRef.Specific)
  Duration.DuringNextUntapStepOf _ -> Nothing
  Duration.UntilEndOfTurn -> Nothing
  Duration.Indefinite -> Nothing
  Duration.Perpetual -> Nothing
  Duration.UntilYourNextTurn -> Nothing
  Duration.UntilYourNextStep _ -> Nothing
  Duration.UntilEndOfYourNextTurn -> Nothing
  Duration.DuringYourNextTurn -> Nothing
  Duration.DuringThatExtraTurn -> Nothing
  Duration.ForAsLongAs _ -> Nothing
  Duration.UntilEndOfCombat -> Nothing
  Duration.UntilEndOfCombatOnYourNextTurn -> Nothing
  Duration.UntilPaid _ -> Nothing
  Duration.UntilUsed -> Nothing
  Duration.UntilEvent _ -> Nothing

-- Does a stored effect under this duration FOLLOW its objects across a zone
-- change? CR 400.7's default is no -- the object that arrives is a new object
-- with no memory of the old one -- and Alchemy's "perpetually" is the one
-- duration that says otherwise. The only reader is
-- Parun.Engine.Event.perpetuate, which cannot ask the question itself: this
-- module is the only one that may case on Parun.Types.Expiry.
--
-- Never answers False, which is the whole reason Perpetual is a separate arm:
-- the two share a lifetime and differ here.
follows :: Expiry -> Bool
follows = (== Expiry.Perpetual)

-- CR 611.2a: has this duration's window BEGUN? Every arm but DuringTurnOf,
-- DuringUntapStepOf and DuringExtraTurn states only an end, so the answer for
-- them is True from the moment the effect is stored and a sweep is the whole of
-- their life cycle. Those three name a turn or step that has not started yet,
-- and a reader that asks only whether the row was swept applies it early.
--
-- The reading is dropAtCleanup's, one turn shifted: the window is the first turn
-- of the named player numbered ABOVE the one the duration began on, so it is
-- open exactly while that player is active on such a turn. The row is dropped at
-- that turn's cleanup, so no LATER turn of theirs can be mistaken for it and the
-- bound needs no upper half.
--
-- Asked by Parun.Engine.CombatRestriction, Parun.Engine.AttackRequirement,
-- Parun.Engine.Cast.permitsPlayFromExile, Parun.Engine.PlayerEffect.applying,
-- Parun.Engine.Replacement.collect and Parun.Engine.RestrictedCreatures.prohibited;
-- Parun.EffectLintSpec's windowOffends keeps a window off every other carrier.
begun :: GameState -> Expiry -> Bool
begun gs expiry = case expiry of
  Expiry.DuringTurnOf afterTurn ->
    Turn.isActive gs (AfterTurn.player afterTurn)
      && GameState.turnNumber gs > AfterTurn.turn afterTurn
  -- CR 502.3: open while that player's untap step is under way. A skipped untap
  -- step (CR 500.11) never is, so the window waits for the next one that runs.
  Expiry.DuringUntapStepOf pid -> Turn.isActive gs pid && GameState.phase gs == untapStep
  -- Read live until pinned: open on a turn that is its window.
  Expiry.DuringTurnOfControllerOf afterObjectTurn -> windowReached gs afterObjectTurn
  -- CR 500.7: open exactly while the extra turn it names is the one under way.
  Expiry.DuringExtraTurn stamp -> GameState.extraTurnUnderWay gs == Just stamp
  Expiry.AtCleanup -> True
  Expiry.Never -> True
  Expiry.Perpetual -> True
  Expiry.While {} -> True
  Expiry.AtTurnOf _ -> True
  Expiry.AtStepOf _ -> True
  Expiry.AtEndOfTurnOf _ -> True
  Expiry.AtEndOf _ -> True
  Expiry.AtEndOfCombatOn _ -> True
  Expiry.WhenPaid _ -> True
  Expiry.WhenUsed -> True
  Expiry.OnEvent _ -> True

-- CR 601.3: may this player use this object's exile permission right now? It
-- names them, its duration's window has begun (`begun`), and its own condition
-- holds -- Hama, the Bloodbender's "during your turn", read live against the
-- permission's source as sweepConditional reads a duration's. The one question
-- Parun.Engine.Cast.permitsPlayFromExile and Parun.Engine.Cost's exile arm share,
-- so a cast allowed by some other permission outside this one's window is never
-- priced by it.
permissionOpen :: PlayerId -> ExilePlayPermission.ExilePlayPermission -> GameState -> Bool
permissionOpen pid permission gs =
  let source = ExilePlayPermission.source permission
   in ExilePlayPermission.player permission == pid
        && begun gs (ExilePlayPermission.expiry permission)
        && all
          (Condition.holds (Projection.fullView gs) (Projection.sourceContext gs (Just pid) source) gs source)
          (ExilePlayPermission.condition permission)

-- CR 611.2: a moment at which a stored duration can end. Each sweep below names
-- its moment, and endsAt alone says which expiries end there.
data Moment
  = -- | CR 514.2: the cleanup step.
    Cleanup
  | -- | CR 611.2a / 800.4m: this seat's turn begins, or would have.
    TurnOf PlayerId
  | -- | CR 611.2a: this step of this player's turn begins.
    StepOf StepBegan.StepBegan
  | -- | CR 500.5: this step or phase ends.
    EndOf PhaseSelector
  | -- | CR 611.2b / 704.3: a settle re-reads every "for as long as" condition.
    Settle
  | -- | CR 116.2c: the pay-to-end price this object's effects state was paid.
    -- Ends ALL of them: the printed sentence is the rule's grain, and Gliding
    -- Licid's one sentence stores four.
    PaidFor ObjectId
  | -- | CR 611.2a: the effect was exercised (Quicken, Scout's Warning).
    Used
  | -- | CR 701.27b: this object was turned face down. Ends the effects it is
    -- the source of, PaidFor's grain.
    TurnedFaceDown ObjectId
  | -- | CR 601.2i: this spell became cast.
    Cast ObjectId
  | -- | CR 901.11: a player planeswalked.
    Planeswalked
  deriving (Eq, Show)

-- CR 611.2: does the expiry a row from `source` stores end at this moment? The
-- ONE test every sweep and every early ending asks.
endsAt :: GameState -> Moment -> ObjectId -> Expiry -> Bool
endsAt gs moment source expiry = case expiry of
  Expiry.AtCleanup -> moment == Cleanup
  -- CR 611.2a: lasts until the end of the game, and so does Alchemy's
  -- "perpetually".
  Expiry.Never -> False
  Expiry.Perpetual -> False
  Expiry.While (While.MkWhile you cond) ->
    moment == Settle && not (Condition.holds (Projection.fullView gs) (Projection.sourceContext gs (Just you) source) gs source cond)
  Expiry.AtTurnOf p -> moment == TurnOf p
  -- CR 800.4m's "a specific point in that turn": a departed player's step
  -- never begins, so the duration ends where that turn would have.
  Expiry.AtStepOf began -> moment == StepOf began || departedTurnOf (StepBegan.player began)
  -- CR 611.2a: "until the end of your next turn" ends at that turn's cleanup
  -- (CR 514.2), one NAMED turn later (see Parun.Types.AfterTurn), so the turn the
  -- duration began on is not its next turn. CR 800.4m ends it where a departed
  -- player's next turn would have begun, since that turn's cleanup never runs.
  Expiry.AtEndOfTurnOf afterTurn -> namedTurnEnds Cleanup afterTurn
  -- CR 611.2a: "during that player's next turn" ends where the arm above ends,
  -- by the same reading. Its BEGINNING is `begun`'s half: a row swept before it
  -- began is one whose turn came and went. A departed player's window never
  -- begins either, so CR 800.4m ends it at the same moment.
  Expiry.DuringTurnOf afterTurn -> namedTurnEnds Cleanup afterTurn
  -- CR 500.5: ended as the untap step it names ends; a departed player's never
  -- begins (CR 800.4m).
  Expiry.DuringUntapStepOf pid ->
    (moment == EndOf (PhaseSelector.Step untapStep) && Turn.isActive gs pid) || departedTurnOf pid
  -- Unpinned. Ended by the cleanup of a turn that was its window but had no
  -- declare attackers step to pin it (CR 500.11, a skipped combat), and dropped
  -- as hygiene once its object is gone. Named by an object, so no seat's turn
  -- ends it.
  Expiry.DuringTurnOfControllerOf afterObjectTurn ->
    moment == Cleanup
      && ( Maybe.isNothing (Game.lookupObject (AfterObjectTurn.object afterObjectTurn) gs)
             || windowReached gs afterObjectTurn
         )
  -- CR 611.2a / 500.7: named by a turn rather than a seat, and kept while the
  -- turn it names is pending, so the cleanup that ends that turn -- popped as it
  -- began -- ends it, as does the first cleanup after CR 800.4k spent it
  -- unbegun. Hygiene: `begun` alone decides whether the row applies.
  Expiry.DuringExtraTurn stamp ->
    moment == Cleanup && not (any ((== stamp) . ExtraTurn.createdAt) (GameState.extraTurns gs))
  -- CR 500.5a: EQUALITY on the selector -- dropAtEndOf says why.
  Expiry.AtEndOf window -> moment == EndOf window
  -- CR 500.8: the FIRST combat phase of that turn to end ends it, so an added
  -- combat phase after it finds nothing left. A turn with no combat phase takes
  -- it at cleanup rather than handing it to a later turn of theirs.
  -- docs/decisions.md, "Which combat phase ends a duration until combat on
  -- your next turn".
  Expiry.AtEndOfCombatOn afterTurn ->
    namedTurnEnds (EndOf PhaseSelector.CombatPhase) afterTurn || namedTurnEnds Cleanup afterTurn
  -- CR 116.2c: only a payment ends this, and CR 800.4m does not reach it -- the
  -- offer goes with the departed player's objects.
  Expiry.WhenPaid _ -> moment == PaidFor source
  -- CR 611.2a: ended by its use (Parun.Engine.PlayerEffect.spentGrants, or a
  -- delayed trigger's firing, `firesOnce`), and at cleanup, since every printed
  -- producer also says "this turn".
  Expiry.WhenUsed -> moment == Used || moment == Cleanup
  -- CR 611.2a / 701.27b: ended by its source turning face down. A source that
  -- has left the game's objects (CR 400.7) can never turn face down, so the row
  -- is dropped at the next settle instead: it covers only that old id, but
  -- Parun.Engine.Interchangeable still reads every row's timestamp.
  Expiry.OnEvent (EventExpiry.MkEventExpiry _ DurationEvent.SourceTurnedFaceDown) ->
    moment == TurnedFaceDown source || (moment == Settle && Maybe.isNothing (Game.lookupObject source gs))
  -- CR 611.2a / 601.2i: ended by a cast its criterion matches, read off the
  -- spell from the baked seat. Not by its source leaving: the effect is a
  -- resolved one, which outlives it.
  Expiry.OnEvent (EventExpiry.MkEventExpiry you (DurationEvent.SpellCast criterion)) -> case moment of
    Cast spell -> Filter.matches (Projection.sourceContext gs (Just you) source) (Projection.viewOfObject spell gs) criterion
    _ -> False
  -- CR 901.11: ended by any player's planeswalk, which
  -- Parun.Engine.Planechase.encounterTop sweeps. Not by its source leaving: the
  -- effect is a resolved one, and its plane is walked away from by the very
  -- planeswalk that ends it.
  Expiry.OnEvent (EventExpiry.MkEventExpiry _ DurationEvent.Planeswalked) -> moment == Planeswalked
  where
    departedTurnOf p = moment == TurnOf p && List.notElem p (Game.stillPlaying gs)
    namedTurnEnds at afterTurn =
      ( moment == at
          && Turn.isActive gs (AfterTurn.player afterTurn)
          && GameState.turnNumber gs > AfterTurn.turn afterTurn
      )
        || departedTurnOf (AfterTurn.player afterTurn)

-- CR 603.7b: does a delayed trigger from `source` under this stated duration
-- trigger only once? With none it does, and firing is the use a Used expiry
-- waits for, so Chandra, the Firebrand's "when you next cast ... this turn"
-- fires once (its 2011-09-22 ruling: "the next instant or sorcery spell you
-- cast that turn") and lapses at cleanup unfired.
firesOnce :: GameState -> ObjectId -> Maybe Expiry -> Bool
firesOnce gs source = maybe True (endsAt gs Used source)

-- CR 611.2a: end every stored row whose expiry ends at this moment.
-- Delete-and-recompute (design.md 2.5): dropping the stored entry makes the next
-- projection revert -- nothing is explicitly undone.
sweep :: Moment -> GameState -> GameState
sweep moment gs = keepWhere (\source -> not . endsAt gs moment source) gs

-- CR 514.2: "until end of turn" and "this turn" effects end during the cleanup
-- step.
--
-- A turn whose ENDING PHASE was skipped never reaches the cleanup step's
-- turn-based actions, and Engine.cleanupSecondAction runs this there anyway: CR
-- 611.2a ends the duration when the turn ends, whether or not the step that
-- normally sweeps it happened.
--
-- CR 116.2d's ignores are among the rows swept: every printed one says until
-- end of turn, so Leonin Arbiter stops the next turn's searches again, with
-- nothing to reinstate.
dropAtCleanup :: GameState -> GameState
dropAtCleanup gs =
  let swept = sweep Cleanup gs
   in -- Rule 702.171b's mark holds no Expiry, so traverseExpiries does not walk it.
      swept {GameState.objects = clearedSaddles (GameState.objects swept)}

-- CR 611.2b: drop every While whose condition has stopped holding. The effect
-- is DELETED, not masked: the duration is one continuous period, so an effect
-- that has ended stays ended even if the condition becomes true again. Reports
-- whether it changed anything, so Engine.settleForPriority knows to run again.
--
-- CR 704.3 fixes the coarsest moment anything can OBSERVE the condition, and
-- settleForPriority runs at exactly the points where the board can change, so
-- checking here is indistinguishable from checking continuously.
--
-- `changed` is a scan over sourcedExpiries rather than a compare of rebuilt
-- carriers, and `State.put` is skipped when nothing changed, so a no-op sweep
-- -- the usual one, since this runs at every settle -- rewrites nothing.
sweepConditional :: Game Bool
sweepConditional = do
  gs <- State.get
  let changed = any (uncurry (endsAt gs Settle)) (sourcedExpiries gs) || any (orphanedHostCopy gs) (GameState.copyEffects gs)
  Monad.when changed $ State.put (dropOrphanedHostCopies (sweep Settle gs))
  pure changed

-- CR 611.3b / 400.7: a static ability's copy row (CopyCoverage.SourceHost, or an
-- Attachment carved off one)
-- states no expiry, and ends when its source is gone: the object that left is
-- no more, and whatever it became is a new one. Hygiene only, since
-- Game.copyCovers already reads nothing off a missing source, but
-- Parun.Engine.Interchangeable reads every row's timestamp.
orphanedHostCopy :: GameState -> ActiveCopy.ActiveCopy -> Bool
orphanedHostCopy gs row = case ActiveCopy.covers row of
  CopyCoverage.SourceHost _ -> Maybe.isNothing (Game.lookupObject (ActiveCopy.source row) gs)
  CopyCoverage.Attachment _ -> Maybe.isNothing (Game.lookupObject (ActiveCopy.source row) gs)
  CopyCoverage.These _ -> False

dropOrphanedHostCopies :: GameState -> GameState
dropOrphanedHostCopies gs = gs {GameState.copyEffects = filter (not . orphanedHostCopy gs) (GameState.copyEffects gs)}

-- CR 701.35a's duration, ended: a detain lasts "until the next turn of the
-- controller of that spell or ability", which is dropAtTurnOf's own moment, so
-- that seat is dropped from every permanent detained until it. CLEARED rather
-- than dropped: the carrier is a field on an object that stays.
--
-- Rule 701.35a fixes the duration, so Object.detainedUntil holds no
-- Parun.Types.Expiry, remembers only whose turn ends it, and this sweep is the
-- only one that can reach it. A permanent detained by two players loses one
-- seat here and stays detained by the other.
--
-- Scanned before rebuilding: almost every board has nothing detained, and this
-- runs at every seat of every handoff.
clearedDetentions :: PlayerId -> Map.Map ObjectId Object.Object -> Map.Map ObjectId Object.Object
clearedDetentions pid objects =
  if any (Set.member pid . Object.detainedUntil) objects
    then Map.map (\o -> o {Object.detainedUntil = Set.delete pid (Object.detainedUntil o)}) objects
    else objects

-- CR 701.15a's duration, ended: a goad lasts "until the next turn of the
-- controller of that spell or ability", which is dropAtTurnOf's own moment, so
-- that seat is dropped from every permanent goaded by it. clearedDetentions'
-- shape and every one of its reasons, down to the scan before the rebuild -- CR
-- 701.15c is why a permanent two players goaded loses one seat here and stays
-- goaded by the other.
clearedGoads :: PlayerId -> Map.Map ObjectId Object.Object -> Map.Map ObjectId Object.Object
clearedGoads pid objects =
  if any (Set.member pid . Object.goadedBy) objects
    then Map.map (\o -> o {Object.goadedBy = Set.delete pid (Object.goadedBy o)}) objects
    else objects

-- CR 702.171b's second ending: saddled lasts "until the end of the turn or it
-- leaves the battlefield", and this is the first of those -- the second is CR
-- 400.7's new object, which needs no sweep. The only designation with a clock;
-- see Parun.Types.Designation. clearedGoads' shape, without its seat: rule
-- 702.171b's mark names no player.
clearedSaddles :: Map.Map ObjectId Object.Object -> Map.Map ObjectId Object.Object
clearedSaddles objects =
  if any (Set.member Designation.Saddled . Object.designations) objects
    then Map.map (\o -> o {Object.designations = Set.delete Designation.Saddled (Object.designations o)}) objects
    else objects

-- CR 611.2a: a duration a spell or ability states lasts as long as it says, so
-- an until-your-next-turn duration ends as that player's turn begins.
--
-- Takes the player EXPLICITLY rather than reading GameState.activePlayer,
-- because CR 800.4m needs this to fire for a seat whose turn does not begin: a
-- departed player's durations last until their turn WOULD have begun. Engine's
-- turn handoff walks the seating order and calls this at every seat it passes.
--
-- Dropping at the handoff is observably identical to dropping "as the turn
-- begins": CR 500.12, CR 502.4 and CR 704.3 leave nothing that could observe
-- the difference. The first observation point is the upkeep step (CR 503.1).
dropAtTurnOf :: PlayerId -> GameState -> GameState
dropAtTurnOf pid gs =
  let swept = sweep (TurnOf pid) gs
   in swept {GameState.objects = clearedGoads pid (clearedDetentions pid (GameState.objects swept))}

-- CR 611.2a: "during its controller's next turn" pinned to a seat as a declare
-- attackers step ends on a turn that is its window (`windowReached`). From here
-- the row is an ordinary DuringTurnOf, so it lasts the rest of this turn (an
-- extra combat included) and dropAtCleanup ends it. A control change before
-- then moves the window, one after does not (Gideon, Battle-Forged's 2015-06-22
-- ruling). A turn with no combat reaches no declare attackers step, so
-- dropAtCleanup asks `windowReached` itself.
--
-- data/scenarios/combat/cr-611-2a-wall-of-dust-follows-the-attacker-to-its-new-controller.json,
-- cr-611-2a-gideon-s-requirement-follows-a-creature-handed-over-before-combat.json,
-- cr-611-2a-a-skipped-combat-still-spends-wall-of-dust-s-window.json,
-- cr-611-2a-a-creature-taken-during-its-new-controller-s-turn-spends-that-turn-s-window.json
-- and cr-611-2a-a-window-spent-at-declare-attackers-stays-spent-after-a-later-control-change.json
-- prove it.
pinAfterDeclareAttackers :: GameState -> GameState
pinAfterDeclareAttackers gs =
  let pin expiry = case expiry of
        Expiry.DuringTurnOfControllerOf afterObjectTurn
          | windowReached gs afterObjectTurn,
            Just pid <- View.controllerOf (AfterObjectTurn.object afterObjectTurn) gs ->
              Expiry.DuringTurnOf (AfterTurn.MkAfterTurn pid (AfterObjectTurn.turn afterObjectTurn))
        _ -> expiry
   in mapExpiries pin gs

-- Is this turn the window "during its controller's next turn" names? A later
-- turn whose active player controls the object now. Whether the creature could
-- legally attack does not matter: the Gideon ruling's first paragraph keeps a
-- tapped or summoning-sick creature inside the window, where it just doesn't
-- attack. A phased-out permanent is not under its controller's control (CR
-- 702.26d), so its window waits.
windowReached :: GameState -> AfterObjectTurn.AfterObjectTurn -> Bool
windowReached gs afterObjectTurn =
  let oid = AfterObjectTurn.object afterObjectTurn
   in GameState.turnNumber gs > AfterObjectTurn.turn afterObjectTurn
        && Set.member oid (GameState.battlefield gs)
        && maybe False (Turn.isActive gs) (View.controllerOf oid gs)

-- CR 611.2: every stored row that carries an expiry, walked once. The ONE
-- place that names the carriers: every sweep, the rewrite and the offer in this
-- module go through it, so a carrier added here reaches all of them and one
-- left out reaches none. `edit` is handed each row's source and expiry and
-- answers the expiry the row keeps, or Nothing to end it.
--
-- A row ended is DROPPED from its list, except an object's play permission
-- (CR 601.3, Object.playableFromExile), which is CLEARED on an object that
-- stays. A delayed trigger stating no duration (CR 603.7b) has no expiry to
-- hand over, so `edit` never sees it and it is kept.
traverseExpiries :: (Applicative f) => (ObjectId -> Expiry -> f (Maybe Expiry)) -> GameState -> f GameState
traverseExpiries edit gs =
  let delayed x = case DelayedTrigger.expiry x of
        Nothing -> pure (Just x)
        Just e -> fmap (fmap (\e' -> x {DelayedTrigger.expiry = Just e'})) (edit (DelayedTrigger.source x) e)
      object o = case Object.playableFromExile o of
        Nothing -> pure o
        Just p ->
          fmap
            (\kept -> o {Object.playableFromExile = fmap (\e -> p {ExilePlayPermission.expiry = e}) kept})
            (edit (ExilePlayPermission.source p) (ExilePlayPermission.expiry p))
      set ce co re pe br ar op ap ev ia dt ob =
        gs
          { GameState.continuousEffects = ce,
            GameState.copyEffects = co,
            GameState.replacements = re,
            GameState.playerEffects = pe,
            GameState.blockRequirements = br,
            GameState.attackRequirements = ar,
            GameState.objectProhibitions = op,
            GameState.attackProhibitions = ap,
            GameState.evasions = ev,
            GameState.ignoredAbilities = ia,
            GameState.delayedTriggers = dt,
            GameState.objects = ob
          }
   in set
        <$> rows edit ContinuousEffect.source ContinuousEffect.expiry (\x e -> x {ContinuousEffect.expiry = e}) (GameState.continuousEffects gs)
        <*> rows edit ActiveCopy.source ActiveCopy.expiry (\x e -> x {ActiveCopy.expiry = e}) (GameState.copyEffects gs)
        <*> rows edit ActiveReplacement.source ActiveReplacement.expiry (\x e -> x {ActiveReplacement.expiry = e}) (GameState.replacements gs)
        <*> rows edit ActivePlayerEffect.source ActivePlayerEffect.expiry (\x e -> x {ActivePlayerEffect.expiry = e}) (GameState.playerEffects gs)
        <*> rows edit ActiveBlockRequirement.source ActiveBlockRequirement.expiry (\x e -> x {ActiveBlockRequirement.expiry = e}) (GameState.blockRequirements gs)
        <*> rows edit ActiveAttackRequirement.source ActiveAttackRequirement.expiry (\x e -> x {ActiveAttackRequirement.expiry = e}) (GameState.attackRequirements gs)
        <*> rows edit ActiveObjectProhibition.source ActiveObjectProhibition.expiry (\x e -> x {ActiveObjectProhibition.expiry = e}) (GameState.objectProhibitions gs)
        <*> rows edit ActiveAttackProhibition.source ActiveAttackProhibition.expiry (\x e -> x {ActiveAttackProhibition.expiry = e}) (GameState.attackProhibitions gs)
        <*> rows edit ActiveEvasion.source ActiveEvasion.expiry (\x e -> x {ActiveEvasion.expiry = e}) (GameState.evasions gs)
        <*> rows edit IgnoredAbility.source IgnoredAbility.expiry (\x e -> x {IgnoredAbility.expiry = e}) (GameState.ignoredAbilities gs)
        <*> fmap (Seq.fromList . Maybe.catMaybes) (traverse delayed (Foldable.toList (GameState.delayedTriggers gs)))
        <*> traverse object (GameState.objects gs)

-- One carrier's list under traverseExpiries' edit, survivors in order.
rows :: (Applicative f) => (ObjectId -> Expiry -> f (Maybe Expiry)) -> (r -> ObjectId) -> (r -> Expiry) -> (r -> Expiry -> r) -> [r] -> f [r]
rows edit source expiry set =
  fmap Maybe.catMaybes . traverse (\x -> fmap (fmap (set x)) (edit (source x) (expiry x)))

-- traverseExpiries under Identity: each row kept under the expiry `edit`
-- answers, or ended.
editExpiries :: (ObjectId -> Expiry -> Maybe Expiry) -> GameState -> GameState
editExpiries edit = Identity.runIdentity . traverseExpiries (\source -> Identity.Identity . edit source)

-- Every stored expiry rewritten in place.
mapExpiries :: (Expiry -> Expiry) -> GameState -> GameState
mapExpiries f = editExpiries (const (Just . f))

-- CR 611.2a: a sweep whose survivors are named by the row's source and expiry.
keepWhere :: (ObjectId -> Expiry -> Bool) -> GameState -> GameState
keepWhere survives = editExpiries (\source expiry -> if survives source expiry then Just expiry else Nothing)

-- CR 500.5's first clause: effects lasting until the end of a step or phase
-- expire as it ends. The window that is ending is passed in, because only the
-- caller knows which one it is -- Engine.runStepThatBegan for a step that ended
-- by itself, and at the end of the last step of a stepped phase there are TWO,
-- the step and the phase, so it calls this twice. Parun.Engine.Resolve's CR 724.1
-- and CR 724.2 arms are the other callers, for a PHASE ended part-way through,
-- where no last step runs to ask.
--
-- EQUALITY on the selector, not containment: CR 500.5a (repeated by CR 511.2)
-- is precisely the claim that an "until end of combat" effect does NOT expire
-- when the end of combat step ends as a step, and containment would end it at
-- the first combat step it saw. Parun.Engine.Turn.inWindow is the containment
-- test, and it answers a different question for a different reader.
dropAtEndOf :: PhaseSelector -> GameState -> GameState
dropAtEndOf ending =
  (if ending == PhaseSelector.Step (Phase.Combat CombatStep.DeclareAttackers) then pinAfterDeclareAttackers else id)
    . sweep (EndOf ending)

-- CR 116.2c: every offer a payment could end right now, paired with the object
-- that stored it. The one reader of Expiry.WhenPaid outside the sweeps, and the
-- reason that arm is not Expiry.Never -- a duration nothing ends by time still
-- has to be FINDABLE by the player who may end it.
--
-- Every carrier, through sourcedExpiries: Parun.Types.Duration is one
-- vocabulary and any opcode taking a duration could print this one, so a carrier
-- left out would hold an effect that is offered to nobody and ends never. The
-- pair is the source and the offer -- the price and CR 109.5's seat, which
-- is all CR 116.2c needs. WHICH of the source's effects is not asked, since one
-- printed sentence stores several and the rule ends the sentence.
paidExpiries :: GameState -> [(ObjectId, PaidExpiry.PaidExpiry)]
paidExpiries gs = [(source, paid) | (source, Expiry.WhenPaid paid) <- sourcedExpiries gs]

-- Every stored expiry in the game, paired with the object it came from:
-- traverseExpiries read rather than rebuilt.
sourcedExpiries :: GameState -> [(ObjectId, Expiry)]
sourcedExpiries = Const.getConst . traverseExpiries (\source expiry -> Const.Const [(source, expiry)])

-- CR 502: the untap step, the window Expiry.DuringUntapStepOf names.
untapStep :: Phase.Phase
untapStep = Phase.Beginning BeginningStep.Untap
