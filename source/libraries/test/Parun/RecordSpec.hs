-- Covers Parun.Play.Record and Parun.Scenario's game start: a played game saved
-- as a scenario, and that scenario replayed.
module Parun.RecordSpec where

import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Either as Either
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Data.Word as Word
import qualified Parun.BotSpec as BotSpec
import qualified Parun.ClientSpec as ClientSpec
import qualified Parun.Codec.Scenario as Codec.Scenario
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Play.Bot as Bot
import qualified Parun.Play.Game as Game
import qualified Parun.Play.Record as Record
import qualified Parun.Registry as Registry
import qualified Parun.Scenario as Scenario
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Answer as Answer
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Entry as Entry
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GraveyardOrder as GraveyardOrder
import qualified Parun.Types.Hotseat as Hotseat
import qualified Parun.Types.Label as Label
import qualified Parun.Types.Move as Move
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Reply as Reply
import qualified Parun.Types.Result as Result
import qualified Parun.Types.Scenario as Scenario.Type
import qualified Parun.Types.SplitMix as SplitMix
import qualified Parun.Types.Terminal as Terminal
import qualified Parun.Types.Timed as Timed

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
    let seats = Map.fromList [(S.alice, Game.human (lifted (ClientSpec.screen 40 ClientSpec.plays)) (const (Right Nothing))), (S.bob, Bot.bot)]
        (outcome, (timeline, cut)) = watched 1 seats Map.empty matchup
    replayed <- Scenario.run registry (saved matchup timeline)
    Spec.assertEqWith s "cut" (fmap fst outcome) (Left (Text.pack "end of input"))
    case replayed of
      Right final -> Spec.assertBool s (Just final == cut) "stopped where it was cut"
      Left failure -> Spec.assertFailure s (Text.unpack (Scenario.render failure))

  Spec.it s "CR 404.3: a seat arranging its graveyard is asked again on replay" $ do
    matchup <- BotSpec.bears s registry
    let orders = Map.fromList [(S.alice, GraveyardOrder.Matters), (S.bob, GraveyardOrder.Matters)]
        -- Seed 5's game puts cards into a graveyard together twice.
        (outcome, (timeline, _)) = watched 5 bots orders matchup
        arranged = Seq.filter ((== Just (Text.pack "ArrangeGraveyardArrivals")) . answered) timeline
    Spec.assertBool s (not (Seq.null arranged)) "a seat arranged a batch"
    replayed <- Scenario.run registry (savedWith orders matchup timeline)
    case (outcome, replayed) of
      (Right (result, _), Right final) -> Spec.assertEqWith s "same result" (GameState.result final) (Just result)
      (_, Left failure) -> Spec.assertFailure s (Text.unpack (Scenario.render failure))
      (Left reason, _) -> Spec.assertFailure s (Text.unpack reason)

  Spec.it s "CR 405.2: a seat targeting a trigger names it by its place on the stack" $ do
    matchup <- stifles s registry
    let (outcome, timeline) = recorded bots matchup
    Spec.assertBool s (any targetsStack timeline) "a seat targeted the stack"
    replayed <- Scenario.run registry (saved matchup timeline)
    case (outcome, replayed) of
      (Right (result, _), Right final) -> Spec.assertEqWith s "same result" (GameState.result final) (Just result)
      (_, Left failure) -> Spec.assertFailure s (Text.unpack (Scenario.render failure))
      (Left reason, _) -> Spec.assertFailure s (Text.unpack reason)

  Spec.it s "a timeline missing an answer fails to replay" $ do
    matchup <- BotSpec.bears s registry
    let (_, timeline) = recorded bots matchup
        half = Seq.length timeline `div` 2
    -- An attack from the second half on: a passed priority left out replays
    -- the same, the runner passing for a seat with nothing scheduled.
    missing <- maybe (Spec.assertFailure s "no attack to leave out") (pure . (+ half)) (Seq.findIndexL attacks (Seq.drop half timeline))
    replayed <- Scenario.run registry (saved matchup (Seq.deleteAt missing timeline))
    Spec.assertBool s (Either.isLeft replayed) "desync"

-- Whether an entry chooses targets, one of them named by its place on the
-- stack.
targetsStack :: Timed.Timed -> Bool
targetsStack timed = case Timed.entry timed of
  Entry.Do (Move.Answer answer) -> Answer.prompt answer == Text.pack "ChooseTargets" && onStack (Answer.with answer)
  _ -> False
  where
    onStack reply = case reply of
      Reply.Text text -> Text.isPrefixOf (Text.pack "stack ") text
      Reply.Array replies -> any onStack replies
      Reply.Object fields -> any (onStack . snd) fields
      _ -> False

-- Two seats of Council of Advisors, whose enters trigger is on the stack for a
-- Stifle to target.
stifles :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck))
stifles s registry = do
  council <- S.printingOf s registry "Council of Advisors"
  stifle <- S.printingOf s registry "Stifle"
  island <- S.printingOf s registry "Island"
  let deck = Deck.fromCards (Map.fromList [(council, 8), (stifle, 8), (island, 8)])
  pure ((S.alice, deck) NonEmpty.:| [(S.bob, deck)])

-- The prompt an entry answers, if it answers one.
answered :: Timed.Timed -> Maybe Text.Text
answered timed = case Timed.entry timed of
  Entry.Do (Move.Answer answer) -> Just (Answer.prompt answer)
  _ -> Nothing

-- Whether an entry declares attackers, any at all.
attacks :: Timed.Timed -> Bool
attacks timed = case Timed.entry timed of
  Entry.Do (Move.Answer answer) -> Answer.prompt answer == Text.pack "DeclareAttackers" && Answer.with answer /= Reply.Array []
  _ -> False

-- The entries recorded so far and the state the last prompt was asked in,
-- over the screen a person reads.
type Base = State.StateT (Seq.Seq Timed.Timed, Maybe GameState.GameState) (State.State ClientSpec.Screen)

-- A game seeded 1 between these seats, and every entry its answers recorded,
-- however it ended.
recorded :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Game.Play Base)) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), Seq.Seq Timed.Timed)
recorded seats matchup = fmap fst (watched 1 seats Map.empty matchup)

-- recorded's game at a seed, each seat at its graveyard order in `orders`.
watched :: Word.Word64 -> Map.Map PlayerId.PlayerId (Answerer.Answerer (Game.Play Base)) -> Map.Map PlayerId.PlayerId GraveyardOrder.GraveyardOrder -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), (Seq.Seq Timed.Timed, Maybe GameState.GameState))
watched seed seats orders matchup =
  let played = Game.run [Record.recording labels sink, lastAsked] seats Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix seed) orders matchup
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
saved = savedWith Map.empty

-- The scenario a game recorded at these graveyard orders saves as, read back.
savedWith :: Map.Map PlayerId.PlayerId GraveyardOrder.GraveyardOrder -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> Seq.Seq Timed.Timed -> Scenario.Type.Scenario
savedWith orders matchup timeline =
  let scenario = Record.scenario Text.empty (fmap (\(pid, deck) -> (Record.labelOf labels pid, Map.findWithDefault GraveyardOrder.Indifferent pid orders, deck)) matchup) timeline
   in Either.either (error . Text.unpack) id (Codec.decode Codec.Scenario.codec (Codec.encode Codec.Scenario.codec scenario))

labels :: Map.Map PlayerId.PlayerId Label.Label
labels = Map.fromList [(S.alice, Label.MkLabel (Text.pack "alice")), (S.bob, Label.MkLabel (Text.pack "bob"))]
