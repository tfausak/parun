{-# LANGUAGE GADTs #-}

-- Covers: CR 807's Grand Melee variant -- Parun.Engine.Setup.randomSeating
-- (CR 807.3), Parun.Engine.GrandMelee's setUp and
-- handOut (CR 807.2, 807.4a-b), its marker handoff through
-- Parun.Engine.Engine.takeNextTurn (CR 807.4c-d, 807.4g, 807.4i-j), its
-- departures through Parun.Engine.Departure (CR 807.4c, 807.4e-f, 807.4h),
-- and eligible through Parun.Engine.Engine.priorityLoop (CR 807.5a, 104.3a).
--
-- Seats are PlayerIds 0 to n-1 in turn order, seat 0 starting. Every seat has
-- a library of Forests, so turns can be played whole through Engine.runStep.
module Parun.GrandMeleeSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.GrandMelee as GrandMelee
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Departure as Departure.Type
import qualified Parun.Types.EndTurnSignal as EndTurnSignal
import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Phase as Phase
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.TurnMarker as TurnMarker
import qualified Parun.Types.TurnRegisters as TurnRegisters
import qualified Parun.Types.TurnResume as TurnResume

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "GrandMelee" $ do
  -- CR 807.4a's example, and CR 807.4b's hand-out every fourth seat from the
  -- starting player.
  Spec.it s "CR 807.4a sixteen players have four markers and fifteen three" $ do
    Spec.assertEqWith s "CR 807.4a sixteen players" (holders (GrandMelee.setUp (seated 16))) [0, 4, 8, 12]
    Spec.assertEqWith s "CR 807.4a fifteen players" (holders (GrandMelee.setUp (seated 15))) [0, 4, 8]

  -- CR 807.3: five seats, each after seat 0 drawn at random as its last
  -- candidate, sit 0, 4, 3, 2, 1; the one marker then passes left (CR 807.4c)
  -- to seat 4.
  Spec.it s "CR 807.3 the players are seated at random" $ do
    forest <- S.printingOf s registry "Forest"
    let (started, drawnFrom) = S.newGameDrawingLast forest (GrandMelee.setUp (seated 5))
    Spec.assertEqWith s "CR 807.4c the marker passes to seat 4" (turnsAfter 1 started) [(seat 4, False)]
    Spec.assertEqWith s "CR 807.3 each seat drawn from the players not yet seated" drawnFrom (fmap seats [[1, 2, 3, 4], [1, 2, 3], [1, 2]])
    Spec.assertEqWith s "CR 807.3 the seating drawn" (GameState.turnOrder started) (seats [0, 4, 3, 2, 1])

  -- CR 807.4b-d: seats 0 and 4 begin at once. Seat 0's marker passes to seat
  -- 1, which waits (seat 4 holds a marker within three seats) until seat 4's
  -- passes to seat 5, and the two begin together, in number order
  -- (docs/decisions.md, "In what order Grand Melee's running turns are
  -- asked"). Each seat takes one turn in eight, seat 0's marker reaching seat
  -- 4 as seat 4's reaches seat 0.
  Spec.it s "CR 807.4d eight players take turns 0, 4, 1, 5, ..." $ do
    forest <- S.printingOf s registry "Forest"
    Spec.assertEqWith s "CR 807.4d the order" (fmap fst (turnsAfter 9 (melee forest 8))) (seats [4, 1, 5, 2, 6, 3, 7, 4, 0])
    Spec.assertEqWith s "CR 807.4b each turn its own number" (fmap (GameState.turnNumber . snd) (turnStates 9 (melee forest 8))) [2 .. 10]

  -- CR 807.4d over a departed seat: seat 2 concedes during seat 0's turn, so
  -- seat 1, given seat 0's marker, has seats 3, 4 and 5 as its three to the
  -- left and waits while seat 4's marker is at seat 5.
  Spec.it s "CR 807.4d a marker waits while another is within three seats on its left" $ do
    forest <- S.printingOf s registry "Forest"
    let conceded = S.departs Departure.Type.Conceded (seat 2) (melee forest 9)
    Spec.assertEqWith s "CR 807.4d seat 1 waits for seat 5" (fmap fst (turnsAfter 5 conceded)) (seats [4, 5, 1, 6, 3])
    Spec.assertEqWith s "CR 807.4b each turn its own number" (fmap (GameState.turnNumber . snd) (turnStates 5 conceded)) [2 .. 6]

  -- CR 807.4c / 807.4e / 807.4h: seat 4 concedes before its turn begins, at
  -- seven players, so its marker goes to seat 5 at once and seat 0's, the
  -- nearest to seat 4's right, is designated for removal (CR 807.4g) and
  -- removed when seat 0's turn ends.
  Spec.it s "CR 807.4c a departing player's marker passes left at once" $ do
    forest <- S.printingOf s registry "Forest"
    let conceded = S.departs Departure.Type.Conceded (seat 4) (melee forest 8)
    Spec.assertEqWith
      s
      "CR 807.4c / 807.4e the markers"
      (fmap (\m -> (TurnMarker.holder m, TurnMarker.removals m)) (GameState.turnMarkers conceded))
      [(seat 0, 1), (seat 5, 0)]
    Spec.assertEqWith s "CR 807.4g seat 0's marker is removed" (fmap fst (turnsAfter 5 conceded)) (seats [5, 6, 7, 0, 1])
    -- CR 807.4h: seats 3 and 5 are not in each other's range until the next
    -- turn begins.
    Spec.assertEqWith s "CR 807.4h this turn" (Game.inRangeOf (seat 3) (seat 5) conceded) False
    Spec.assertEqWith s "CR 807.4h the next turn" (fmap (Game.inRangeOf (seat 3) (seat 5)) (Maybe.listToMaybe (fmap snd (turnStates 1 conceded)))) (Just True)

  -- CR 807.4j's example: seat 0 casts Capture of Jingzhou ("Take an extra
  -- turn after this one."), then seat 1 concedes, which costs a marker, and
  -- seat 0's is designated (CR 807.4e). Seat 0's marker is removed as the turn
  -- ends, and the extra turn waits until just before seat 0's next turn,
  -- under seat 4's marker, whose turn is already under way (CR 807.4b).
  Spec.it s "CR 807.4j the extra turn waits for the player's next turn" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    capture <- S.printingOf s registry "Capture of Jingzhou"
    let (spellId, staged) = S.addHandCard capture (seat 0) (S.landsFor island (seat 0) 5 (melee forest 8))
        main = untilPhase Phase.PrecombatMain staged
        resolved = snd (Engine.runGamePure S.identityAnswer (S.runPure S.identityAnswer main (S.cast (seat 0) spellId)) Engine.priorityLoop)
        conceded = S.departs Departure.Type.Conceded (seat 1) resolved
    Spec.assertEqWith s "the extra turn is pending" (length (GameState.extraTurns conceded)) 1
    Spec.assertEqWith
      s
      "CR 807.4j the extra turn comes just before seat 0's next turn"
      (turnsAfter 7 conceded)
      [(seat 5, False), (seat 6, False), (seat 7, False), (seat 0, True), (seat 0, False), (seat 2, False), (seat 3, False)]

  -- CR 500.11 / 614.10a: seat 0 casts Meditate ("You skip your next turn."),
  -- so when seat 4's marker reaches seat 0 the turn is skipped and the marker
  -- passes on to seat 1 as at the end of a turn (docs/decisions.md, "Where a
  -- skipped Grand Melee turn leaves its marker"). Seat 1 then waits while
  -- seat 4, holding the other marker, takes its turn.
  Spec.it s "CR 500.11 a skipped turn passes its marker on" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    meditate <- S.printingOf s registry "Meditate"
    let (spellId, staged) = S.addHandCard meditate (seat 0) (S.landsFor island (seat 0) 3 (melee forest 8))
        main = untilPhase Phase.PrecombatMain staged
        resolved = snd (Engine.runGamePure S.identityAnswer (S.runPure S.identityAnswer main (S.cast (seat 0) spellId)) Engine.priorityLoop)
    Spec.assertEqWith s "CR 500.11 seat 0's turn is passed over" (fmap fst (turnsAfter 10 resolved)) (seats [1, 5, 2, 6, 3, 7, 4, 5, 1, 6])

  -- CR 807.4i / 614.10a: seat 0 casts Capture of Jingzhou, then Meditate, so
  -- seat 0 keeps its marker for the extra turn, seat 4's being four seats
  -- away, and that extra turn is the next turn Meditate skips (Magosi, the
  -- Waterveil's ruling). The kept marker then passes on to seat 1, which
  -- waits for seat 4's to move on.
  Spec.it s "CR 807.4i a kept marker's skipped extra turn passes it on" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    capture <- S.printingOf s registry "Capture of Jingzhou"
    meditate <- S.printingOf s registry "Meditate"
    let staged = captureAndMeditate forest island capture meditate 8 0
    Spec.assertEqWith s "the extra turn is pending" (length (GameState.extraTurns staged)) 1
    Spec.assertEqWith s "CR 807.4i seat 0's extra turn is passed over" (turnsAfter 5 staged) (fmap (\n -> (seat n, False)) [1, 5, 2, 6, 3])

  -- CR 807.4i / 614.10a: the same cast by seat 4 on its first turn, which
  -- ends after seat 0's, seat 0's marker then waiting at seat 1, within three
  -- seats on seat 4's right. So seat 4 passes its marker on and takes the
  -- extra turn just before its next turn. Meditate skips that extra turn, and
  -- the marker it arrived on stays for the ordinary turn still owed.
  Spec.it s "CR 807.4i a skipped extra turn keeps the marker for the turn still owed" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    capture <- S.printingOf s registry "Capture of Jingzhou"
    meditate <- S.printingOf s registry "Meditate"
    let staged = captureAndMeditate forest island capture meditate 8 1
    Spec.assertEqWith s "the extra turn is pending" (length (GameState.extraTurns staged)) 1
    Spec.assertEqWith
      s
      "CR 807.4i seat 4 passed its marker on, the extra turn waiting"
      (fmap (fmap ExtraTurn.taker . GameState.extraTurns . snd) (take 2 (turnStates 2 staged)))
      [[seat 4], [seat 4]]
    Spec.assertEqWith s "CR 807.4i seat 4's ordinary turn follows" (turnsAfter 8 staged) (fmap (\n -> (seat n, False)) [1, 5, 2, 6, 3, 7, 4, 0])

  -- CR 807.5a: on seat 0's turn only seats 7, 0 and 1 are within range of the
  -- marker. Once seat 1 has cast Shock, seat 2 is within range of an object's
  -- controller, so is asked too until it resolves.
  Spec.it s "CR 807.5a priority goes to players within range of the marker or of a stack object's controller" $ do
    forest <- S.printingOf s registry "Forest"
    mountain <- S.printingOf s registry "Mountain"
    shock <- S.printingOf s registry "Shock"
    let (shockId, staged) = S.addHandCard shock (seat 1) (S.landsFor mountain (seat 1) 1 (onMain (melee forest 8)))
        cast = S.runPure S.identityAnswer staged (S.cast (seat 1) shockId)
        asked gs = snd (State.execState (Engine.runGame recordAsked gs Engine.priorityLoop) ([], []))
        conceding gs = fst (State.execState (Engine.runGame recordAsked gs Engine.priorityLoop) ([], []))
    Spec.assertEqWith s "the empty stack" (asked staged) (seats [0, 1, 7])
    Spec.assertEqWith s "CR 807.5a Shock on the stack" (asked cast) (seats [0, 1, 2, 7, 0, 1, 7])
    -- CR 104.3a: a player without priority is still asked whether they
    -- concede, as the window opens, and a player with priority as they get it.
    Spec.assertEqWith s "CR 104.3a the others are asked to concede" (conceding cast) (seats [3, 4, 5, 6] <> asked cast)

  -- CR 807.4b / 807.5: in both turns' upkeeps, the questions go round the
  -- markers one priority decision at a time: seat 0's stack asks 0, 1 and 7,
  -- seat 4's asks 4, 5 and 3 (CR 807.5a), interleaved (docs/decisions.md, "In
  -- what order Grand Melee's running turns are asked").
  Spec.it s "CR 807.4b both running turns' questions alternate" $ do
    forest <- S.printingOf s registry "Forest"
    let units = Monad.replicateM_ 12 Engine.runStep
        asked = snd (State.execState (Engine.runGame recordAsked (melee forest 8) units) ([], []))
    Spec.assertEqWith s "CR 807.4b the asked seats" (take 6 asked) (seats [0, 4, 1, 5, 7, 3])

  -- CR 807.5 / 725.1b: seat 4 has Shock on its marker's stack when seat 0's
  -- Time Stop resolves on seat 0's. Only seat 0's stack is exiled and only
  -- seat 0's turn ends (docs/decisions.md, "Which stack and turn a resolving
  -- Grand Melee object names").
  Spec.it s "CR 725.1b Time Stop ends only its own marker's turn" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    mountain <- S.printingOf s registry "Mountain"
    shock <- S.printingOf s registry "Shock"
    timeStop <- S.printingOf s registry "Time Stop"
    let main = untilPhase Phase.PrecombatMain (melee forest 8)
        (shockId, withShock) = S.addHandCard shock (seat 4) (S.landsFor mountain (seat 4) 1 main)
        onFour = S.runPure S.identityAnswer (Engine.workOn 2 withShock) (S.cast (seat 4) shockId)
        shocked = Engine.workOn 1 onFour
        (stopId, withStop) = S.addHandCard timeStop (seat 0) (S.landsFor island (seat 0) 6 shocked)
        cast = S.runPure S.identityAnswer withStop (S.cast (seat 0) stopId)
        resolved = snd (Engine.runGamePure S.identityAnswer cast Engine.priorityLoop)
        parked = Map.lookup 2 (GameState.parkedTurns resolved)
    Spec.assertEqWith s "CR 725.1 seat 0's turn ends" (GameState.endTurnSignal resolved) EndTurnSignal.Ended
    Spec.assertEqWith s "Shock is on seat 4's stack" (length (GameState.stack onFour)) 1
    Spec.assertEqWith s "CR 807.5 Shock stays on seat 4's stack" (fmap TurnRegisters.stack parked) (Just (GameState.stack onFour))
    Spec.assertEqWith s "CR 807.5 seat 4's turn runs on" (fmap TurnRegisters.endTurnSignal parked) (Just EndTurnSignal.Running)
    -- CR 807.4b: seat 4's own Time Stop ends turn 2 before seat 0's turn 1,
    -- and the turns that begin next are numbered past both.
    let (fourStop, withFourStop) = S.addHandCard timeStop (seat 4) (S.landsFor island (seat 4) 6 (Engine.workOn 2 main))
        fourCast = S.runPure S.identityAnswer withFourStop (S.cast (seat 4) fourStop)
        fourResolved = snd (Engine.runGamePure S.identityAnswer fourCast Engine.priorityLoop)
    Spec.assertEqWith s "CR 807.4b each turn its own number" (fmap (\((p, _), st) -> (p, GameState.turnNumber st)) (turnStates 2 fourResolved)) [(seat 1, 3), (seat 5, 4)]

  -- CR 807.5b: a spell targets objects on its own stack only. Seat 2's Shock
  -- is on seat 0's marker's stack and seat 4's on seat 4's, so seat 3 has
  -- priority for both (CR 807.5a) and both controllers are in its range;
  -- its Counterspell, cast on seat 4's, is offered seat 4's Shock alone.
  Spec.it s "CR 807.5b Counterspell is offered its own stack's spells" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    mountain <- S.printingOf s registry "Mountain"
    shock <- S.printingOf s registry "Shock"
    counterspell <- S.printingOf s registry "Counterspell"
    let main = untilPhase Phase.PrecombatMain (melee forest 8)
        (zeroShock, withZero) = S.addHandCard shock (seat 2) (S.landsFor mountain (seat 2) 1 main)
        zeroCast = S.runPure S.identityAnswer withZero (S.cast (seat 2) zeroShock)
        (fourShock, withFour) = S.addHandCard shock (seat 4) (S.landsFor mountain (seat 4) 1 (Engine.workOn 2 zeroCast))
        fourCast = S.runPure S.identityAnswer withFour (S.cast (seat 4) fourShock)
        (counterId, staged) = S.addHandCard counterspell (seat 3) (S.landsFor island (seat 3) 2 fourCast)
        offered = State.execState (Engine.runGame recordTargets staged (S.cast (seat 3) counterId)) []
    Spec.assertEqWith s "a Shock is on each stack" (fmap length [GameState.stack zeroCast, GameState.stack fourCast, Game.allStacks staged]) [1, 1, 2]
    Spec.assertEqWith s "CR 807.5b the target menu" offered [Set.fromList (fmap Recipient.ToObject (GameState.stack fourCast))]

  -- CR 807.5b: with Shocks on both markers' stacks as above, seat 3 holds
  -- priority in both windows. Reached on seat 0's, it is asked which stack it
  -- acts on, chooses seat 4's, and its Counterspell goes there.
  Spec.it s "CR 807.5b a player with priority for several stacks chooses one" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    mountain <- S.printingOf s registry "Mountain"
    shock <- S.printingOf s registry "Shock"
    counterspell <- S.printingOf s registry "Counterspell"
    let main = untilPhase Phase.PrecombatMain (melee forest 8)
        (zeroShock, withZero) = S.addHandCard shock (seat 2) (S.landsFor mountain (seat 2) 1 main)
        zeroCast = S.runPure S.identityAnswer withZero (S.cast (seat 2) zeroShock)
        (fourShock, withFour) = S.addHandCard shock (seat 4) (S.landsFor mountain (seat 4) 1 (Engine.workOn 2 zeroCast))
        fourCast = S.runPure S.identityAnswer withFour (S.cast (seat 4) fourShock)
        (_, withCounter) = S.addHandCard counterspell (seat 3) (S.landsFor island (seat 3) 2 fourCast)
        holds r = r {TurnRegisters.priority = Just (seat 3), TurnRegisters.turnResume = TurnResume.InWindow}
        staged =
          withCounter
            { GameState.priority = Just (seat 3),
              GameState.turnResume = TurnResume.InWindow,
              GameState.parkedTurns = Map.adjust holds 1 (GameState.parkedTurns withCounter)
            }
        ((_, acted), asked) = State.runState (Engine.runGame chooseLast staged Engine.runStep) []
        stacks gs = Map.insert (Maybe.fromMaybe 0 (Turn.workedMarker gs)) (length (GameState.stack gs)) (fmap (length . TurnRegisters.stack) (GameState.parkedTurns gs))
    Spec.assertEqWith s "seat 4's turn is worked" (Turn.workedMarker staged) (Just 2)
    Spec.assertEqWith s "CR 807.5b seat 3 is asked" asked [(seat 3, [1, 2])]
    Spec.assertEqWith s "CR 807.5b Counterspell is on seat 4's stack" (stacks acted) (Map.fromList [(1, 1), (2, 2)])

  -- CR 102.1 / 807.4: seat 4's Gideon Blackblade is a 4/4 creature while
  -- seat 0's turn is worked, seat 4's turn running beside it; seat 2's, whose
  -- turn is not running, is not (docs/decisions.md, "Which turn a Grand Melee
  -- read of the active player means").
  Spec.it s "CR 807.4 it is your turn while your marker's turn runs" $ do
    forest <- S.printingOf s registry "Forest"
    gideon <- S.printingOf s registry "Gideon Blackblade"
    let main = untilPhase Phase.PrecombatMain (melee forest 8)
        (fours, withFours) = S.addPermanent gideon (seat 4) main
        (twos, staged) = S.addPermanent gideon (seat 2) withFours
    Spec.assertEqWith s "seat 0's turn is worked" (GameState.activePlayer staged) (seat 0)
    Spec.assertEqWith s "CR 807.4 seat 4's Gideon" (Projection.powerOf fours staged) (Just 4)
    Spec.assertEqWith s "CR 102.1 seat 2's Gideon" (Projection.powerOf twos staged) Nothing
  where
    seat = PlayerId.MkPlayerId
    seats :: [Natural] -> [PlayerId]
    seats = fmap seat
    seated n = Setup.emptyGame (seat 0 NonEmpty.:| fmap seat [1 .. n - 1])
    holders gs = fmap (PlayerId.unwrap . TurnMarker.holder) (GameState.turnMarkers gs)
    onMain gs = gs {GameState.phase = Phase.PrecombatMain, GameState.priority = Just (seat 0)}

-- The seat of `n` whose turn begins `turns` turns in casts Capture of
-- Jingzhou, then Meditate, in that turn's first main phase.
captureAndMeditate :: Printing.Printing -> Printing.Printing -> Printing.Printing -> Printing.Printing -> Natural -> Int -> GameState.GameState
captureAndMeditate forest island capture meditate n turns =
  let begun = Maybe.fromMaybe (melee forest n) (Maybe.listToMaybe (reverse (fmap snd (turnStates turns (melee forest n)))))
      caster = GameState.activePlayer begun
      (captureId, withCapture) = S.addHandCard capture caster (S.landsFor island caster 8 begun)
      (meditateId, staged) = S.addHandCard meditate caster withCapture
      resolve gs = snd (Engine.runGamePure S.identityAnswer gs Engine.priorityLoop)
      captured = resolve (S.runPure S.identityAnswer (untilPhase Phase.PrecombatMain staged) (S.cast caster captureId))
   in resolve (S.runPure S.identityAnswer captured (S.cast caster meditateId))

-- A Grand Melee game of `n` seats, each with ten Forests in their library.
melee :: Printing.Printing -> Natural -> GameState.GameState
melee forest n =
  let pids = fmap PlayerId.MkPlayerId [0 .. n - 1]
      start = GrandMelee.setUp (Setup.emptyGame (PlayerId.MkPlayerId 0 NonEmpty.:| drop 1 pids))
      stock gs pid = iterate (snd . S.addLibraryCard forest pid) gs !! 10
   in Foldable.foldl' stock start pids

-- Run scheduler units until this phase is the one to run next in the turn
-- GameState's fields hold.
untilPhase :: Phase.Phase -> GameState.GameState -> GameState.GameState
untilPhase phase gs0 =
  let pid = GameState.activePlayer gs0
      go budget gs =
        if budget <= (0 :: Int) || (GameState.phase gs == phase && GameState.activePlayer gs == pid)
          then gs
          else go (budget - 1) (S.runPure S.identityAnswer gs Engine.runStep)
   in go 400 gs0

-- Every running turn's number and marker, the worked one's first.
runningTurns :: GameState.GameState -> [(Natural, Natural)]
runningTurns gs =
  [(GameState.turnNumber gs, w) | w <- Maybe.maybeToList (Turn.workedMarker gs)] <> [(TurnRegisters.turnNumber r, n) | (n, r) <- Map.toList (GameState.parkedTurns gs)]

-- The next `n` turns to begin, in the order CR 807.4b numbers them, each with
-- the state as it begins, its turn worked. Bounded at 400 units a turn.
turnStates :: Int -> GameState.GameState -> [((PlayerId, Bool), GameState.GameState)]
turnStates n gs0 =
  let highest gs = maximum (fmap fst (runningTurns gs))
      go k budget gs
        | k <= 0 || budget <= (0 :: Int) = []
        | otherwise =
            let next = S.runPure S.identityAnswer gs Engine.runStep
                begun = List.sortOn fst (filter ((> highest gs) . fst) (runningTurns next))
                states = [Engine.workOn marker next | (_, marker) <- begun]
                entries = [((GameState.activePlayer st, Maybe.isJust (GameState.extraTurnUnderWay st)), st) | st <- states]
             in if null begun
                  then go k (budget - 1) next
                  else take k entries <> go (k - length entries) 400 next
   in go n 400 gs0

-- Who takes each of the next `n` turns, and whether it is an extra turn.
turnsAfter :: Int -> GameState.GameState -> [(PlayerId, Bool)]
turnsAfter n gs = fmap fst (turnStates n gs)

-- Records who is asked Prompt.Concede and who Prompt.ChooseAction, in order;
-- everything is answered as S.identityAnswer answers it.
recordAsked :: Prompt.Prompt r -> State.State ([PlayerId], [PlayerId]) r
recordAsked p = case p of
  Prompt.Concede pid -> do
    State.modify' (\(conceding, acting) -> (conceding <> [pid], acting))
    pure (S.identityAnswer p)
  Prompt.ChooseAction _ pid _ -> do
    State.modify' (\(conceding, acting) -> (conceding, acting <> [pid]))
    pure (S.identityAnswer p)
  _ -> pure (S.identityAnswer p)

-- Records who is asked Prompt.ChooseTurnMarker and what it offers, and
-- answers the last marker offered; casts as S.castAnswer does.
chooseLast :: Prompt.Prompt r -> State.State [(PlayerId, [Natural])] r
chooseLast p = case p of
  Prompt.ChooseTurnMarker _ pid markers -> do
    State.modify' (<> [(pid, NonEmpty.toList markers)])
    pure (NonEmpty.last markers)
  _ -> pure (S.castAnswer p)

-- Records the target menu each Prompt.ChooseTargets offers, every slot's
-- recipients in one set; everything is answered as S.identityAnswer answers it.
recordTargets :: Prompt.Prompt r -> State.State [Set.Set Recipient.Recipient] r
recordTargets p = case p of
  Prompt.ChooseTargets _ _ _ slots -> do
    State.modify' (<> [foldMap snd slots])
    pure (S.identityAnswer p)
  _ -> pure (S.identityAnswer p)
