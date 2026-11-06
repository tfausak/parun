{-# LANGUAGE GADTs #-}

-- Covers: CR 807's Grand Melee variant -- Parun.Engine.GrandMelee's setUp and
-- handOut (CR 807.2, 807.4a-b), its marker handoff through
-- Parun.Engine.Engine.takeNextTurn (CR 807.4c-d, 807.4g, 807.4i-j), its
-- departures through Parun.Engine.Departure (CR 807.4c, 807.4e-f, 807.4h),
-- and eligible through Parun.Engine.Engine.priorityLoop (CR 807.5a, 104.3a).
--
-- Seats are PlayerIds 0 to n-1 in turn order, seat 0 starting. Every seat has
-- a library of Forests, so turns can be played whole through Engine.runStep.
module Parun.GrandMeleeSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Maybe as Maybe
import Numeric.Natural (Natural)
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.GrandMelee as GrandMelee
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Departure as Departure.Type
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Phase as Phase
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.TurnMarker as TurnMarker

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "GrandMelee" $ do
  -- CR 807.4a's example, and CR 807.4b's hand-out every fourth seat from the
  -- starting player.
  Spec.it s "CR 807.4a sixteen players have four markers and fifteen three" $ do
    Spec.assertEqWith s "CR 807.4a sixteen players" (holders (GrandMelee.setUp (seated 16))) [0, 4, 8, 12]
    Spec.assertEqWith s "CR 807.4a fifteen players" (holders (GrandMelee.setUp (seated 15))) [0, 4, 8]

  -- CR 807.4b-d: seat 0's marker passes to seat 1, which waits (seat 4 holds
  -- a marker within three seats) until seat 4 has taken its turn. Each seat
  -- takes one turn in eight, seat 0's marker reaching seat 4 as seat 4's
  -- reaches seat 0.
  Spec.it s "CR 807.4d eight players take turns 0, 4, 1, 5, ..." $ do
    forest <- S.printingOf s registry "Forest"
    Spec.assertEqWith s "CR 807.4d the order" (fmap fst (turnsAfter 9 (melee forest 8))) (seats [4, 1, 5, 2, 6, 3, 7, 4, 0])

  -- CR 807.4d over a departed seat: seat 2 concedes during seat 0's turn, so
  -- seat 1, given seat 0's marker, has seats 3, 4 and 5 as its three to the
  -- left and waits while seat 4's marker is at seat 5.
  Spec.it s "CR 807.4d a marker waits while another is within three seats on its left" $ do
    forest <- S.printingOf s registry "Forest"
    let conceded = S.departs Departure.Type.Conceded (seat 2) (melee forest 9)
    Spec.assertEqWith s "CR 807.4d seat 1 waits for seat 5" (fmap fst (turnsAfter 5 conceded)) (seats [4, 5, 1, 6, 3])

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
  -- under seat 4's marker.
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
      [(seat 4, False), (seat 5, False), (seat 6, False), (seat 7, False), (seat 0, True), (seat 0, False), (seat 2, False)]

  -- CR 500.11 / 614.10a: seat 0 casts Meditate ("You skip your next turn."),
  -- so when seat 4's marker reaches seat 0 the turn is skipped and the marker
  -- passes on to seat 1 as at the end of a turn, the other marker's seat 5
  -- going first (docs/decisions.md, "Where a skipped Grand Melee turn leaves
  -- its marker").
  Spec.it s "CR 500.11 a skipped turn passes its marker on" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    meditate <- S.printingOf s registry "Meditate"
    let (spellId, staged) = S.addHandCard meditate (seat 0) (S.landsFor island (seat 0) 3 (melee forest 8))
        main = untilPhase Phase.PrecombatMain staged
        resolved = snd (Engine.runGamePure S.identityAnswer (S.runPure S.identityAnswer main (S.cast (seat 0) spellId)) Engine.priorityLoop)
    Spec.assertEqWith s "CR 500.11 seat 0's turn is passed over" (fmap fst (turnsAfter 10 resolved)) (seats [4, 1, 5, 2, 6, 3, 7, 4, 5, 1])

  -- CR 807.4i / 614.10a: seat 0 casts Capture of Jingzhou, then Meditate, so
  -- seat 0 keeps its marker for the extra turn, which waits for seat 4's, and
  -- that extra turn is the next turn Meditate skips (Magosi, the Waterveil's
  -- ruling). The kept marker then passes on to seat 1.
  Spec.it s "CR 807.4i a kept marker's skipped extra turn passes it on" $ do
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    capture <- S.printingOf s registry "Capture of Jingzhou"
    meditate <- S.printingOf s registry "Meditate"
    let (captureId, withCapture) = S.addHandCard capture (seat 0) (S.landsFor island (seat 0) 8 (melee forest 8))
        (meditateId, staged) = S.addHandCard meditate (seat 0) withCapture
        resolve gs = snd (Engine.runGamePure S.identityAnswer gs Engine.priorityLoop)
        main = untilPhase Phase.PrecombatMain staged
        captured = resolve (S.runPure S.identityAnswer main (S.cast (seat 0) captureId))
        resolved = resolve (S.runPure S.identityAnswer captured (S.cast (seat 0) meditateId))
    Spec.assertEqWith s "the extra turn is pending" (length (GameState.extraTurns resolved)) 1
    Spec.assertEqWith s "CR 807.4i seat 0's extra turn is passed over" (turnsAfter 5 resolved) [(seat 4, False), (seat 5, False), (seat 1, False), (seat 6, False), (seat 2, False)]

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
  where
    seat = PlayerId.MkPlayerId
    seats :: [Natural] -> [PlayerId]
    seats = fmap seat
    seated n = Setup.emptyGame (seat 0 NonEmpty.:| fmap seat [1 .. n - 1])
    holders gs = fmap (PlayerId.unwrap . TurnMarker.holder) (GameState.turnMarkers gs)
    onMain gs = gs {GameState.phase = Phase.PrecombatMain, GameState.priority = Just (seat 0)}

-- A Grand Melee game of `n` seats, each with ten Forests in their library.
melee :: Printing.Printing -> Natural -> GameState.GameState
melee forest n =
  let pids = fmap PlayerId.MkPlayerId [0 .. n - 1]
      start = GrandMelee.setUp (Setup.emptyGame (PlayerId.MkPlayerId 0 NonEmpty.:| drop 1 pids))
      stock gs pid = iterate (snd . S.addLibraryCard forest pid) gs !! 10
   in Foldable.foldl' stock start pids

-- Run whole steps until this phase is the one to run next.
untilPhase :: Phase.Phase -> GameState.GameState -> GameState.GameState
untilPhase phase =
  let go budget gs =
        if budget <= (0 :: Int) || GameState.phase gs == phase
          then gs
          else go (budget - 1) (S.runPure S.identityAnswer gs Engine.runStep)
   in go 20

-- The next `n` turns to begin, each with the state as it begins. Bounded at
-- twenty steps a turn.
turnStates :: Int -> GameState.GameState -> [((PlayerId, Bool), GameState.GameState)]
turnStates n gs0 =
  let go k budget gs
        | k <= 0 || budget <= (0 :: Int) = []
        | otherwise =
            let next = S.runPure S.identityAnswer gs Engine.runStep
             in if GameState.turnNumber next /= GameState.turnNumber gs
                  then ((GameState.activePlayer next, Maybe.isJust (GameState.extraTurnUnderWay next)), next) : go (k - 1) 20 next
                  else go k (budget - 1) next
   in go n 20 gs0

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
