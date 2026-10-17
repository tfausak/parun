-- Covers Pawl.Play.Record and Pawl.Scenario's game start: a played game saved
-- as a scenario, and that scenario replayed.
module Pawl.RecordSpec where

import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Either as Either
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Pawl.BotSpec as BotSpec
import qualified Pawl.ClientSpec as ClientSpec
import qualified Pawl.Codec.Scenario as Codec.Scenario
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Game as Game
import qualified Pawl.Play.Record as Record
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.Observer as Observer
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.Scenario as Scenario.Type
import qualified Pawl.Types.SplitMix as SplitMix
import qualified Pawl.Types.Terminal as Terminal
import qualified Pawl.Types.Timed as Timed

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Record" $ do
  Spec.it s "a recorded bot game replays clean to the same result" $ do
    matchup <- BotSpec.bears s registry
    let (outcome, timeline) = recorded bots matchup
    replayed <- Scenario.run registry (saved matchup timeline)
    case (outcome, replayed) of
      (Right (result, _), Right final) -> Spec.assertEqWith s "same result" (GameState.result final) (Just result)
      (_, Left failure) -> Spec.assertFailure s (Text.unpack (Scenario.render failure))
      (Left reason, _) -> Spec.assertFailure s (Text.unpack reason)

  Spec.it s "a game cut short replays to where it stopped" $ do
    matchup <- BotSpec.bears s registry
    let seats = Map.fromList [(S.alice, Game.human (lifted (ClientSpec.screen 40 ClientSpec.plays))), (S.bob, Bot.bot)]
        (outcome, (timeline, cut)) = watched seats matchup
    replayed <- Scenario.run registry (saved matchup timeline)
    Spec.assertEqWith s "cut" (fmap fst outcome) (Left (Text.pack "end of input"))
    case replayed of
      Right final -> Spec.assertBool s (Just final == cut) "stopped where it was cut"
      Left failure -> Spec.assertFailure s (Text.unpack (Scenario.render failure))

  Spec.it s "a timeline missing an answer fails to replay" $ do
    matchup <- BotSpec.bears s registry
    let (_, timeline) = recorded bots matchup
    replayed <- Scenario.run registry (saved matchup (Seq.deleteAt (Seq.length timeline `div` 2) timeline))
    Spec.assertBool s (Either.isLeft replayed) "desync"

-- The entries recorded so far and the state the last prompt was asked in,
-- over the screen a person reads.
type Base = State.StateT (Seq.Seq Timed.Timed, Maybe GameState.GameState) (State.State ClientSpec.Screen)

-- A seeded game between these seats, and every entry its answers recorded,
-- however it ended.
recorded :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Game.Play Base)) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), Seq.Seq Timed.Timed)
recorded seats matchup = fmap fst (watched seats matchup)

watched :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Game.Play Base)) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), (Seq.Seq Timed.Timed, Maybe GameState.GameState))
watched seats matchup =
  let played = Game.run [Record.recording labels sink, lastAsked] seats Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix 1) matchup
   in State.evalState (State.runStateT played (Seq.empty, Nothing)) ClientSpec.blank

lastAsked :: Observer.Observer (Game.Play Base)
lastAsked = Observer.MkObserver {Observer.before = Game.underneath . State.modify' . fmap . const . Just . Asked.game, Observer.after = \_ _ -> pure ()}

sink :: Timed.Timed -> Game.Play Base ()
sink entry = Game.underneath (State.modify' (Bifunctor.first (Seq.|> entry)))

bots :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Game.Play Base))
bots = Map.fromList [(S.alice, Bot.bot), (S.bob, Bot.bot)]

lifted :: Terminal.Terminal (State.State ClientSpec.Screen) -> Terminal.Terminal Base
lifted terminal =
  Terminal.MkTerminal
    { Terminal.say = Trans.lift . Terminal.say terminal,
      Terminal.listen = Trans.lift (Terminal.listen terminal),
      Terminal.clear = Trans.lift (Terminal.clear terminal)
    }

saved :: NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> Seq.Seq Timed.Timed -> Scenario.Type.Scenario
saved matchup timeline =
  let scenario = Record.scenario Text.empty (fmap (Bifunctor.first (Record.labelOf labels)) matchup) timeline
   in Either.either (error . Text.unpack) id (Codec.decode Codec.Scenario.codec (Codec.encode Codec.Scenario.codec scenario))

labels :: Map.Map PlayerId.PlayerId Label.Label
labels = Map.fromList [(S.alice, Label.MkLabel (Text.pack "alice")), (S.bob, Label.MkLabel (Text.pack "bob"))]
