{-# LANGUAGE GADTs #-}

-- Covers Pawl.Engine.Fragmented and its call in Pawl.Engine.Engine.priorityLoop:
-- CR 732.3's fragmented loop, out of two synthetic printings -- Synthetic Self
-- Tapper ("{0}: Tap this creature") under alice and Synthetic Rouser ("{0}:
-- Untap target creature") under bob. No printing reaches the rule: Scryfall
-- `o:"{0}: untap"` and `o:"{0}: tap"`, 2026-10-03, answer only untaps limited
-- to one activation a turn or a game (Instill Energy, Nature's Chosen, Touch
-- of Vitae) and Chimeric Idol, which taps lands. CR 732.3's own example,
-- which undoes a continuous effect, is Mist Dragon's.
--
-- Two seats, so alice -- active, and involved -- is the named player by
-- construction. The answerer is test-local: it sequences two players through
-- one script and records each menu alice is offered, which the harness cannot.
module Pawl.FragmentedSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.ContinuousEffect as ContinuousEffect
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.Expiry as Expiry
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.ModifyTarget as ModifyTarget
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Recipient as Recipient

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "a fragmented loop (CR 732.3)" $ do
  Spec.it s "the active player may not repeat the action that returned the game to a state" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    -- Alice taps her creature, bob untaps it, and the game is back where it
    -- began: her second offer there lacks the activation, and Pass remains.
    Spec.assertEqWith s "CR 732.3 alice's activation is withheld where the state recurs" (fst (offers (loopBoard tapper rouser Nothing False))) [True, False]

  Spec.it s "a state that does not recur leaves the activation offered" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    -- The control: bob untaps alice's OTHER creature, tapped at setup, so the
    -- lap ends in a state not seen before and alice may activate again. Only
    -- the lap after that one, whose untap is a no-op, recurs.
    Spec.assertEqWith s "CR 732.3 a new state is no loop" (fst (offers (loopBoard tapper rouser Nothing True))) [True, True, False]

  Spec.it s "a card reading history the loop does not write leaves the loop detected" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    ghoul <- S.printingOf s registry "Khabál Ghoul"
    harvest <- S.printingOf s registry "Ominous Harvest"
    -- CR 732.3's example: "nothing in the game cares how many times an ability
    -- has been activated". Khabál Ghoul, in alice's library, counts the
    -- turn's deaths off the log, and the lap kills nothing, so the state
    -- still recurs. Ominous Harvest reads the same deaths through the
    -- gravestorm trigger Pawl.Engine.Keyword mints -- the card itself spells
    -- only the keyword.
    Spec.assertEqWith s "CR 732.3 Khabál Ghoul leaves alice's activation withheld" (fst (offers (loopBoard tapper rouser (Just ghoul) False))) [True, False]
    Spec.assertEqWith s "CR 732.3 Ominous Harvest leaves alice's activation withheld" (fst (offers (loopBoard tapper rouser (Just harvest) False))) [True, False]

  Spec.it s "a card reading history the loop writes keeps the loop's states distinct" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    ashling <- S.printingOf s registry "Ashling the Pilgrim"
    -- Ashling the Pilgrim, in alice's library, counts an ability's
    -- resolutions this turn off the log, and every lap resolves two. So a card
    -- can tell the recurring state from the first, and the answerer's budget
    -- is what stops her.
    Spec.assertEqWith s "CR 732.3 Ashling keeps every offer" (fst (offers (loopBoard tapper rouser (Just ashling) False))) (replicate (budget + 1) True)

  Spec.it s "an activation with a target to choose is not refused" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    -- The roles swapped: bob taps his creature, alice -- active, so the named
    -- player -- untaps it, and the state recurs. Refusing her Rouser outright
    -- would also refuse aiming it at her own tapped creature, a different
    -- game choice (CR 732.1, 601.2c), so it stays offered (gap #4663).
    Spec.assertEqWith s "CR 732.3 alice's Rouser stays offered" (snd (offers (rouserBoard tapper rouser))) (replicate budget True)

  Spec.it s "a loop whose undo leaves a superseded continuous effect behind is detected" $ do
    dragon <- S.printingOf s registry "Mist Dragon"
    -- CR 732.3's own example, on one card: alice has her Mist Dragon gain
    -- flying, then lose it, and so on. Every resolution stores an indefinite
    -- effect (CR 611.2a), so no two states are equal as stored; a gain a later
    -- loss erases is unobservable, as is a loss a later loss repeats. The
    -- fourth resolution returns to the state the second left, where she had it
    -- gain flying, so that activation is withheld and the loss is not.
    let (gains, loses) = unzip (dragonOffers (S.addPermanent dragon S.alice (Setup.emptyGame S.bothPlayers)))
    Spec.assertEqWith s "CR 732.3 alice's gain is withheld where the state recurs" gains [True, True, True, True, False]
    Spec.assertEqWith s "CR 732.3 alice's loss stays offered" loses (replicate 5 True)

  Spec.it s "a superseded effect stamped before a permanent is not one stamped after it" $ do
    dragon <- S.printingOf s registry "Mist Dragon"
    wings <- S.printingOf s registry "Arcanum Wings"
    -- The same loop, begun under a loss of flying stored BEFORE Arcanum Wings
    -- was attached, so the Aura's grant applies after it (CR 613.7) and the
    -- Dragon flies. The second resolution leaves the same one row, the loss,
    -- but stamped after the Aura's: the Dragon does not fly, the state is not
    -- the first one, and only the fourth resolution recurs.
    let board = flownUnder dragon wings
    Spec.assertBool s (uncurry (Projection.hasKeyword Keyword.Flying) board) "CR 613.7 the Dragon flies under the later Aura"
    Spec.assertEqWith s "CR 732.3 alice's gain is withheld only where the state recurs" (fmap fst (dragonOffers board)) [True, True, True, True, False]

-- How many times the answerer has the tapper activate before it passes
-- instead, since without CR 732.3 the loop never ends.
budget :: Int
budget = 3

-- Who taps, who untaps, the two permanents, the Rouser's target, the board.
type Lap = (PlayerId.PlayerId, PlayerId.PlayerId, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)

-- alice, active in her precombat main phase with an empty stack, controls two
-- Synthetic Self Tappers, the second tapped when `otherTapped`; bob controls a
-- Synthetic Rouser and aims it at the first, or at the second when
-- `otherTapped` -- so the two boards differ in exactly bob's target and the
-- second creature's tap state. Nothing is scheduled after this phase.
loopBoard :: Printing.Printing -> Printing.Printing -> Maybe Printing.Printing -> Bool -> Lap
loopBoard tapper rouser reader otherTapped =
  let base = Setup.emptyGame S.bothPlayers
      (first, gs1) = S.addPermanent tapper S.alice base
      (other, gs2) = S.addPermanent tapper S.alice gs1
      (rouserId, gs3) = S.addPermanent rouser S.bob gs2
      gs4 = maybe gs3 (\printing -> snd (S.addLibraryCard printing S.alice gs3)) reader
      placed = inMain gs4
   in if otherTapped
        then (S.alice, S.bob, first, rouserId, other, S.tapObject other placed)
        else (S.alice, S.bob, first, rouserId, first, placed)

-- The roles swapped: bob's untapped Synthetic Self Tapper, alice's Synthetic
-- Rouser aimed at it, and a tapped Self Tapper of alice's the Rouser could
-- untap instead.
rouserBoard :: Printing.Printing -> Printing.Printing -> Lap
rouserBoard tapper rouser =
  let base = Setup.emptyGame S.bothPlayers
      (tapperId, gs1) = S.addPermanent tapper S.bob base
      (rouserId, gs2) = S.addPermanent rouser S.alice gs1
      (own, gs3) = S.addPermanent tapper S.alice gs2
   in (S.bob, S.alice, tapperId, rouserId, tapperId, S.tapObject own (inMain gs3))

inMain :: GameState.GameState -> GameState.GameState
inMain gs =
  gs
    { GameState.phase = Phase.PrecombatMain,
      GameState.remaining = Seq.empty,
      GameState.activePlayer = S.alice,
      GameState.priority = Just S.alice
    }

-- Run one priority loop on the board and answer whether the tapper's
-- activation was on each menu they got at the head of a lap, and whether the
-- Rouser's was on each menu its controller got once the tap resolved.
offers :: Lap -> ([Bool], [Bool])
offers (tapping, rousing, tapperId, rouserId, target, gs) =
  let ((_, _), (_, _, offered, roused)) = State.runState (Engine.runGame (looping tapping rousing tapperId rouserId target) gs Engine.priorityLoop) (0, 0, [], [])
   in (offered, roused)

-- One lap of the loop as a script, in stages: 0, the tapper at the lap's head
-- activates (within the budget) and the offer is recorded; 1, the other player
-- passes on the ability; 2, they activate the Rouser once it has resolved, the
-- offer recorded; 3, the tapper passes on it. Every other prompt passes or
-- declines.
looping :: PlayerId.PlayerId -> PlayerId.PlayerId -> ObjectId.ObjectId -> ObjectId.ObjectId -> ObjectId.ObjectId -> Prompt.Prompt r -> State.State (Int, Int, [Bool], [Bool]) r
looping tapping rousing tapperId rouserId target p = case p of
  Prompt.ChooseAction _ pid actions -> do
    (stage, activations, offered, roused) <- State.get
    let activationsOf oid = filter (activates oid) actions
    case (stage :: Int, activationsOf tapperId, activationsOf rouserId) of
      (0, own, _) | pid == tapping -> do
        let seen = offered <> [not (null own)]
        case own of
          action : _ | activations < budget -> do
            State.put (1, activations + 1, seen, roused)
            pure action
          _ -> do
            State.put (0, activations, seen, roused)
            pure Action.Pass
      (1, _, _) | pid == rousing -> do
        State.put (2, activations, offered, roused)
        pure Action.Pass
      (2, _, rouse) | pid == rousing -> do
        let seen = roused <> [not (null rouse)]
        case rouse of
          action : _ -> do
            State.put (3, activations, offered, seen)
            pure action
          [] -> do
            State.put (2, activations, offered, seen)
            pure Action.Pass
      (3, _, _) | pid == tapping -> do
        State.put (0, activations, offered, roused)
        pure Action.Pass
      _ -> pure Action.Pass
  -- FILTERED out of the offer, never built (CR 608.2b re-reads it).
  Prompt.ChooseTargets _ _ _ sets -> pure (fmap (Set.filter (== Recipient.ToCreature target) . snd) sets)
  _ -> pure (S.identityAnswer p)

activates :: ObjectId.ObjectId -> Action.Action -> Bool
activates oid action = case action of
  Action.Activate source _ -> source == oid
  _ -> False

-- alice's Mist Dragon, stored as losing flying (the row its second ability
-- leaves, CR 611.2a) before her Arcanum Wings enchants it.
flownUnder :: Printing.Printing -> Printing.Printing -> (ObjectId.ObjectId, GameState.GameState)
flownUnder dragon wings =
  let (dragonId, gs1) = S.addPermanent dragon S.alice (Setup.emptyGame S.bothPlayers)
      (ts, gs2) = Game.freshTimestamp gs1
      loss =
        ContinuousEffect.MkContinuousEffect
          { ContinuousEffect.source = dragonId,
            ContinuousEffect.timestamp = ts,
            ContinuousEffect.expiry = Expiry.Never,
            ContinuousEffect.modification = Modification.LoseKeyword Keyword.Flying,
            ContinuousEffect.affected = Affected.TheseObjects (Set.singleton dragonId)
          }
      (wingsId, gs3) = S.addPermanent wings S.alice gs2 {GameState.continuousEffects = [loss]}
   in (dragonId, S.attach wingsId dragonId gs3)

-- alice, active in her precombat main phase with an empty stack and no mana,
-- controls the Mist Dragon and alternates its two {0} abilities, gain first,
-- up to `budget` times twice over; bob passes throughout. Answers, at each
-- prompt alice gets with the stack empty, whether each of the two was on the
-- menu.
dragonOffers :: (ObjectId.ObjectId, GameState.GameState) -> [(Bool, Bool)]
dragonOffers (dragonId, gs) =
  let ((_, _), (_, _, offered)) = State.runState (Engine.runGame (alternating dragonId) (inMain gs) Engine.priorityLoop) (False, 0, [])
   in offered

-- The state: whether alice's ability is on the stack, how many she has
-- activated, and the menus recorded so far.
alternating :: ObjectId.ObjectId -> Prompt.Prompt r -> State.State (Bool, Int, [(Bool, Bool)]) r
alternating dragonId p = case p of
  Prompt.ChooseAction _ pid actions | pid == S.alice -> do
    (pending, activations, offered) <- State.get
    if pending
      then do
        State.put (False, activations, offered)
        pure Action.Pass
      else do
        let ofKind gains = filter (\action -> activates dragonId action && gainsFlying action == Just gains) actions
            menu = (not (null (ofKind True)), not (null (ofKind False)))
            wanted = ofKind (even activations)
        case wanted of
          action : _ | activations < 2 * budget -> do
            State.put (True, activations + 1, offered <> [menu])
            pure action
          _ -> do
            State.put (False, activations, offered <> [menu])
            pure Action.Pass
  Prompt.ChooseAction {} -> pure Action.Pass
  _ -> pure (S.identityAnswer p)

-- Whether a Mist Dragon activation gains flying (Just True) or loses it (Just
-- False), read off the modification it stores.
gainsFlying :: Action.Action -> Maybe Bool
gainsFlying action = case action of
  Action.Activate _ ability ->
    case [ModifyTarget.modification modify | mode <- Foldable.toList (Modal.modes (ActivatedAbility.modal ability)), Effect.ModifyTarget modify <- Foldable.toList (Mode.allEffects mode)] of
      [Modification.GainKeyword _] -> Just True
      [Modification.LoseKeyword _] -> Just False
      _ -> Nothing
  _ -> Nothing
