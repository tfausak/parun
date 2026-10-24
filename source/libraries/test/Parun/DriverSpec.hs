-- Covers Parun.Engine.Driver: routing prompts to answerers by seat, observers
-- around each answer, and stepping a game until it ends or is told to stop.
module Parun.DriverSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Response as Response

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Driver" $ do
  Spec.it s "each seat's prompts reach that seat's answerer, and chance reaches the fallback" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let answerer = Driver.bySeat (Map.fromList [(S.alice, tagged "alice"), (S.bob, tagged "bob")]) (tagged "chance")
        seen = State.execState (Driver.match [] answerer GameSettings.plain matchup) []
        by tag = [seat | (t, seat) <- seen, t == tag]
    Spec.assertBool s (not (null (by "alice"))) "alice answered"
    Spec.assertBool s (not (null (by "bob"))) "bob answered"
    Spec.assertBool s (not (null (by "chance"))) "chance answered"
    Spec.assertBool s (all (== Just S.alice) (by "alice")) "alice's only"
    Spec.assertBool s (all (== Just S.bob) (by "bob")) "bob's only"
    Spec.assertBool s (all Maybe.isNothing (by "chance")) "chance only"
  Spec.it s "a seat with no answerer of its own reaches the fallback" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let answerer = Driver.bySeat (Map.singleton S.alice (tagged "alice")) (tagged "rest")
        seen = State.execState (Driver.match [] answerer GameSettings.plain matchup) []
    Spec.assertBool s (elem ("rest", Just S.bob) seen) "bob to rest"
  Spec.it s "observers see each prompt before its answer and each answer after, in the order a recording does" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let observer :: Observer.Observer (State.State [Maybe Response.Response])
        observer =
          Observer.MkObserver
            { Observer.before = \_ -> State.modify' (<> [Nothing]),
              Observer.after = \asked answer -> State.modify' (<> [Just (Replay.encode (Asked.prompt asked) answer)])
            }
        seen = State.execState (Driver.match [observer] casting GameSettings.plain matchup) []
        recorded = snd (Replay.record S.castAnswer (start0 matchup) (Engine.playFrom matchup))
    Spec.assertBool s (alternates seen) "alternates"
    Spec.assertEqWith s "transcript" (Maybe.catMaybes seen) recorded
  Spec.it s "drive stops when its predicate says so" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let stopped = State.evalState (Driver.drive [] casting 1000 (\gs -> pure (GameState.turnNumber gs >= 3)) (started matchup)) ()
    Spec.assertEqWith s "turn" (GameState.turnNumber stopped) 3
    Spec.assertBool s (Maybe.isNothing (GameState.result stopped)) "unfinished"
  Spec.it s "drive returns a finished game rather than outrunning it" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let finished = State.evalState (Driver.drive [] casting 100000 (const (pure False)) (started matchup)) ()
        played = snd (Engine.runMatchPure S.castAnswer GameSettings.plain matchup)
    Spec.assertBool s (Maybe.isJust (GameState.result finished)) "finished"
    Spec.assertBool s (finished == played) "ended state"
  Spec.it s "a budget of 0 takes no step" $ do
    matchup <- S.redRed (S.printingOf s registry)
    let start = started matchup
        after = State.evalState (Driver.drive [] casting 0 (const (pure False)) start) ()
    Spec.assertBool s (after == start) "untouched"

-- Answers as S.castAnswer does, logging who each prompt was for under `tag`.
tagged :: String -> Answerer.Answerer (State.State [(String, Maybe PlayerId.PlayerId)])
tagged tag = Answerer.MkAnswerer $ \asked ->
  S.castAnswer (Asked.prompt asked) <$ State.modify' (<> [(tag, Driver.deciderOf (Asked.prompt asked))])

casting :: (Monad m) => Answerer.Answerer m
casting = Answerer.MkAnswerer (pure . S.castAnswer . Asked.prompt)

start0 :: NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> GameState.GameState
start0 matchup = Setup.gameWith GameSettings.plain (fmap fst matchup)

-- A game set up and ready for its first step.
started :: NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> GameState.GameState
started matchup = snd (Engine.runGamePure S.castAnswer (start0 matchup) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))

-- Whether a log runs before, after, before, after, and so on.
alternates :: [Maybe Response.Response] -> Bool
alternates entries = case entries of
  [] -> True
  Nothing : Just _ : rest -> alternates rest
  _ -> False
