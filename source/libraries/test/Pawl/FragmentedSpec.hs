{-# LANGUAGE GADTs #-}

-- Covers Pawl.Engine.Fragmented and its call in Pawl.Engine.Engine.priorityLoop:
-- CR 732.3's fragmented loop, out of two synthetic printings -- Synthetic Self
-- Tapper ("{0}: Tap this creature") under alice and Synthetic Rouser ("{0}:
-- Untap target creature") under bob. No printing reaches the rule: Scryfall
-- `o:"{0}: untap"` and `o:"{0}: tap"`, 2026-10-03, answer only untaps limited
-- to one activation a turn or a game (Instill Energy, Nature's Chosen, Touch
-- of Vitae) and Chimeric Idol, which taps lands. CR 732.3's own example,
-- which undoes a continuous effect, is Mist Dragon's, and a loop through a
-- targeted activation is two Grim Poppets', or two Fatestitchers'.
--
-- Two seats, so alice -- active, and involved -- is the named player by
-- construction. The answerer is test-local: it sequences two players through
-- one script and records each menu alice is offered, which the harness cannot.
module Pawl.FragmentedSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List as List
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
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.ContinuousEffect as ContinuousEffect
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.Expiry as Expiry
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.ModifyTarget as ModifyTarget
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.OptionalDecision as OptionalDecision
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
    Spec.assertEqWith s "CR 732.3 alice's activation is withheld where the state recurs" (offers (loopBoard tapper rouser Nothing False)) [True, False]

  Spec.it s "a state that does not recur leaves the activation offered" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    -- The control: bob untaps alice's OTHER creature, tapped at setup, so the
    -- lap ends in a state not seen before and alice may activate again. Only
    -- the lap after that one, whose untap is a no-op, recurs.
    Spec.assertEqWith s "CR 732.3 a new state is no loop" (offers (loopBoard tapper rouser Nothing True)) [True, True, False]

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
    Spec.assertEqWith s "CR 732.3 Khabál Ghoul leaves alice's activation withheld" (offers (loopBoard tapper rouser (Just ghoul) False)) [True, False]
    Spec.assertEqWith s "CR 732.3 Ominous Harvest leaves alice's activation withheld" (offers (loopBoard tapper rouser (Just harvest) False)) [True, False]

  Spec.it s "a card reading history the loop writes keeps the loop's states distinct" $ do
    tapper <- S.printingOf s registry "Synthetic Self Tapper"
    rouser <- S.printingOf s registry "Synthetic Rouser"
    ashling <- S.printingOf s registry "Ashling the Pilgrim"
    -- Ashling the Pilgrim, in alice's library, counts an ability's
    -- resolutions this turn off the log, and every lap resolves two. So a card
    -- can tell the recurring state from the first, and the answerer's budget
    -- is what stops her.
    Spec.assertEqWith s "CR 732.3 Ashling keeps every offer" (offers (loopBoard tapper rouser (Just ashling) False)) (replicate (budget + 1) True)

  Spec.it s "an activation is refused as announced, not as a whole" $ do
    poppet <- S.printingOf s registry "Grim Poppet"
    bears <- S.printingOf s registry "Grizzly Bears"
    -- alice moves her Grim Poppet's -1/-1 counter onto bob's, and bob moves
    -- it back, each removing it as the cost (CR 118.1). The lap ends where it
    -- began but for the stamps: the counter's is new (CR 613.7c), and bob's
    -- Poppet keeps an inert one. Canonical, they recur, and alice aiming at
    -- bob's Poppet again is refused; aiming at her Grizzly Bears is a
    -- different game choice (CR 732.1, 601.2c) and goes ahead.
    Spec.assertEqWith s "CR 732.3 only alice's repeated aim is refused" (poppetAttempts poppet bears) [(False, True), (False, False), (True, True)]

  Spec.it s "a choice the resolution offers does not make a repeated activation a new one" $ do
    stitcher <- S.printingOf s registry "Fatestitcher"
    -- alice taps her Fatestitcher to untap bob's, and bob taps his to untap
    -- hers: the lap ends where it began. Her activation asked her whether to
    -- untap as it resolved (CR 608.2d), a later game choice of its own; the
    -- one CR 732.3 refuses is activating it again as she did.
    Spec.assertEqWith s "CR 732.3 alice's repeated aim is refused" (stitcherAttempts stitcher) [(False, True), (False, False)]

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

inMain :: GameState.GameState -> GameState.GameState
inMain gs =
  gs
    { GameState.phase = Phase.PrecombatMain,
      GameState.remaining = Seq.empty,
      GameState.activePlayer = S.alice,
      GameState.priority = Just S.alice
    }

-- Run one priority loop on the board and answer whether the tapper's
-- activation was on each menu they got at the head of a lap.
offers :: Lap -> [Bool]
offers (tapping, rousing, tapperId, rouserId, target, gs) =
  let ((_, _), (_, _, offered)) = State.runState (Engine.runGame (looping tapping rousing tapperId rouserId target) gs Engine.priorityLoop) (0, 0, [])
   in offered

-- One lap of the loop as a script, in stages: 0, the tapper at the lap's head
-- activates (within the budget) and the offer is recorded; 1, the other player
-- passes on the ability; 2, they activate the Rouser once it has resolved; 3,
-- the tapper passes on it. Every other prompt passes or declines.
looping :: PlayerId.PlayerId -> PlayerId.PlayerId -> ObjectId.ObjectId -> ObjectId.ObjectId -> ObjectId.ObjectId -> Prompt.Prompt r -> State.State (Int, Int, [Bool]) r
looping tapping rousing tapperId rouserId target p = case p of
  Prompt.ChooseAction _ pid actions -> do
    (stage, activations, offered) <- State.get
    let activationsOf oid = filter (activates oid) actions
    case (stage :: Int, activationsOf tapperId, activationsOf rouserId) of
      (0, own, _) | pid == tapping -> do
        let seen = offered <> [not (null own)]
        case own of
          action : _ | activations < budget -> do
            State.put (1, activations + 1, seen)
            pure action
          _ -> do
            State.put (0, activations, seen)
            pure Action.Pass
      (1, _, _) | pid == rousing -> do
        State.put (2, activations, offered)
        pure Action.Pass
      (2, _, rouse) | pid == rousing -> case rouse of
        action : _ -> do
          State.put (3, activations, offered)
          pure action
        [] -> pure Action.Pass
      (3, _, _) | pid == tapping -> do
        State.put (0, activations, offered)
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

-- What the aiming answerer carries: the targets alice has yet to aim at, the
-- target the activation under way aims at, whether alice has just attempted
-- one, whether the lap is hers to open, and each of her attempts as (aimed at
-- the alternative, went on the stack).
type Aiming = ([ObjectId.ObjectId], Maybe ObjectId.ObjectId, Bool, Bool, [(Bool, Bool)])

-- alice, active in her precombat main phase, controls a Grim Poppet carrying
-- one -1/-1 counter and a Grizzly Bears; bob controls a Grim Poppet with none.
-- alice aims her Poppet at bob's twice, then at her Bears.
poppetAttempts :: Printing.Printing -> Printing.Printing -> [(Bool, Bool)]
poppetAttempts poppet bears =
  let (alices, gs1) = S.addPermanent poppet S.alice (Setup.emptyGame S.bothPlayers)
      (bobs, gs2) = S.addPermanent poppet S.bob gs1
      (bearsId, gs3) = S.addPermanent bears S.alice gs2
   in attempts alices bobs bearsId [bobs, bobs, bearsId] (S.addCounter CounterKind.MinusOneMinusOne 1 alices gs3)

-- alice, active in her precombat main phase, controls an untapped
-- Fatestitcher; bob controls a tapped one. alice aims hers at bob's twice.
stitcherAttempts :: Printing.Printing -> [(Bool, Bool)]
stitcherAttempts stitcher =
  let (alices, gs1) = S.addPermanent stitcher S.alice (Setup.emptyGame S.bothPlayers)
      (bobs, gs2) = S.addPermanent stitcher S.bob gs1
   in attempts alices bobs alices [bobs, bobs] (S.tapObject bobs gs2)

-- Run one priority loop on the board: alice opens each lap by activating
-- `alices` at the next target of `script`, and bob answers each of hers that
-- resolves by aiming `bobs` back at `alices`. Answers alice's attempts, each
-- as whether it aimed at `other` and whether it went on the stack. Every
-- "may" is exercised. The answerer reads the stack off the game it is asked
-- in, which is how it tells a refused attempt from one that went on the
-- stack.
attempts :: ObjectId.ObjectId -> ObjectId.ObjectId -> ObjectId.ObjectId -> [ObjectId.ObjectId] -> GameState.GameState -> [(Bool, Bool)]
attempts alices bobs other script board =
  let ((_, _), (_, _, _, _, made)) = State.runState (Engine.runGameAsked (aiming alices bobs other) (inMain board) Engine.priorityLoop) (script, Nothing, False, True, [])
   in made

aiming :: ObjectId.ObjectId -> ObjectId.ObjectId -> ObjectId.ObjectId -> Asked.Asked r -> State.State Aiming r
aiming alices bobs other asked = case Asked.prompt asked of
  Prompt.ChooseAction _ pid actions -> do
    (script, aim, attempted, alicesLap, made) <- State.get
    let stacked = not (null (GameState.stack (Asked.game asked)))
        activation oid = List.find (activates oid) actions
        open remaining recorded = case (remaining, activation alices) of
          (next : rest, Just action) -> do
            State.put (rest, Just next, True, alicesLap, recorded)
            pure action
          _ -> do
            State.put (remaining, aim, False, alicesLap, recorded)
            pure Action.Pass
    if pid == S.alice
      then
        if attempted
          then do
            let recorded = made <> [(aim == Just other, stacked)]
            if stacked
              then do
                State.put (script, aim, False, False, recorded)
                pure Action.Pass
              else open script recorded
          else
            if not stacked && alicesLap
              then open script made
              else pure Action.Pass
      else case activation bobs of
        Just action | not stacked && not alicesLap -> do
          State.put (script, Just alices, False, True, made)
          pure action
        _ -> pure Action.Pass
  -- FILTERED out of the offer, never built (CR 608.2b re-reads it).
  Prompt.ChooseTargets _ _ _ sets -> do
    (_, aim, _, _, _) <- State.get
    pure (fmap (Set.filter (\recipient -> Recipient.objectOf recipient == aim) . snd) sets)
  Prompt.ChooseOptional {} -> pure OptionalDecision.Exercises
  prompt -> pure (S.identityAnswer prompt)
