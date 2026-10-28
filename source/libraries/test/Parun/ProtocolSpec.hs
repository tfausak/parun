-- Covers Parun.Play.Protocol: a seat's decisions as lines out and answers back,
-- and that nothing a seat may not see reaches its lines.
module Parun.ProtocolSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Either as Either
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Cards as Cards
import qualified Parun.Codec.Cost as Codec.Cost
import qualified Parun.Codec.Filter as Codec.Filter
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Codec.Request as Codec.Request
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Play.Protocol as Protocol
import qualified Parun.Registry as Registry
import qualified Parun.Scenario.Prompt as Scenario.Prompt
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Action as Action
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PayOffer as PayOffer
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Request as Request
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Protocol" $ do
  Spec.it s "every answer in ten turns of a game survives the protocol's encode and decode" $ do
    matchup <- redGreen s registry
    let checking :: Answerer.Answerer (State.State [(Text.Text, Bool)])
        checking = Answerer.MkAnswerer $ \asked -> do
          let prompt = Asked.prompt asked
              answer = S.castAnswer prompt
              back = Protocol.decodeAnswer prompt (Protocol.encodeAnswer prompt answer)
              survives = fmap (Replay.encode prompt) back == Right (Replay.encode prompt answer)
          Maybe.maybe (pure ()) (\_ -> State.modify' (<> [(Scenario.Prompt.kindOf prompt, survives)])) (Driver.deciderOf prompt)
          pure answer
        played = do
          (_, gs) <- Engine.runGameAsked (Answerer.unwrap checking) (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)
          Driver.drive [] checking 100000 (pure . (>= 10) . GameState.turnNumber) gs
        checks = State.execState played []
    Spec.assertBool s (Set.fromList (fmap Text.pack ["Concede", "DeclareMulligan", "ChooseAction", "ChooseManaSource", "ChooseDiscard"]) `Set.isSubsetOf` Set.fromList (fmap fst checks)) "reached"
    Spec.assertEqWith s "all survive" [kind | (kind, False) <- checks] []
  Spec.it s "attacks, blocks and targets survive the protocol's encode and decode" $ do
    let survives :: Prompt.Prompt r -> r -> Bool
        survives prompt answer = fmap (Replay.encode prompt) (Protocol.decodeAnswer prompt (Protocol.encodeAnswer prompt answer)) == Right (Replay.encode prompt answer)
        o7 = ObjectId.MkObjectId 7
        o9 = ObjectId.MkObjectId 9
        slot = SlotName.MkSlotName (Text.pack "target")
    Spec.assertBool s (survives (Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [o7, o9]) [o9]) "attackers"
    Spec.assertBool s (survives (Prompt.DeclareBlockers (Decider.MkDecider S.bob) S.bob [o9] [o7]) (Map.singleton o9 (Set.singleton o7))) "blockers"
    Spec.assertBool s (survives (Prompt.ChooseTargets (Decider.MkDecider S.alice) S.alice o7 (Map.singleton slot (1, Set.fromList [Recipient.ToPlayer S.bob, Recipient.ToCreature o9]))) (Map.singleton slot (Set.singleton (Recipient.ToPlayer S.bob)))) "targets"
  Spec.it s "CR 103.1 a seat on the line is asked to play first or draw before the game, with no view" $ do
    let asking replies = State.runState (Protocol.playOrDraw (\line -> State.state (\(out, rest) -> (Maybe.listToMaybe rest, (out <> [line], drop 1 rest)))) S.bob) ([], fmap Text.pack replies)
        (drew, (sent, _)) = asking ["\"Maybe\"", "\"Draw\""]
        requests = fmap (requestOf . Text.unpack) sent
    Spec.assertEqWith s "draws" drew (Just False)
    Spec.assertEqWith s "plays" (fst (asking ["\"Play\""])) (Just True)
    Spec.assertEqWith s "end of input" (fst (asking [])) Nothing
    Spec.assertEqWith s "views" (fmap (fmap Request.view) requests) [Just Nothing, Just Nothing]
    Spec.assertEqWith s "questions" (fmap (fmap Request.question) requests) (replicate 2 (Just (Question.MkQuestion S.bob (Text.pack "PlayOrDraw") (R.Array [R.Text (Text.pack "Play"), R.Text (Text.pack "Draw")]))))
    Spec.assertEqWith s "problems" (fmap (fmap Request.problem) requests) [Just Nothing, Just (Just (Text.pack "expected Play or Draw"))]
  Spec.it s "an activated ability is offered by its place among its source's, so two abilities of one source differ" $ do
    vane <- S.printingOf s registry "Arcum's Weathervane"
    let (oid, gs) = S.addPermanent vane S.alice (Setup.emptyGame S.bothPlayers)
        offered = Protocol.offerOf gs (Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice (fmap (Action.Activate oid) (Projection.abilitiesOf oid gs)))
        activate i = R.Object [(Text.pack "action", R.Text (Text.pack "Activate")), (Text.pack "object", Protocol.object oid), (Text.pack "ability", R.Number i)]
    Spec.assertEqWith s "offer" offered (R.Array [activate 0, activate 1])

  Spec.it s "CR 510.1 a combat damage assignment offers each recipient's lethal damage in the answer's vocabulary" $ do
    let o7 = ObjectId.MkObjectId 7
        lethal = Map.fromList [(Recipient.ToCreature (ObjectId.MkObjectId 9), 2), (Recipient.ToCreature (ObjectId.MkObjectId 11), 3 :: Natural)]
        prompt = Prompt.AssignCombatDamage (Decider.MkDecider S.alice) S.alice o7 lethal 5
        offer = Protocol.offerOf (Setup.emptyGame S.bothPlayers) prompt
    Spec.assertEqWith s "lethal" (fmap (Protocol.decodeAnswer prompt) (field "lethal" offer)) (Just (Right lethal))
    Spec.assertEqWith s "total" (field "total" offer) (Just (R.Number 5))
    Spec.assertEqWith s "source" (field "source" offer) (Just (Protocol.object o7))

  Spec.it s "CR 400.2 a guess offers its source and proposition and never the card" $ do
    let o7 = ObjectId.MkObjectId 7
        proposition = Filter.Type.Measures (Measures.MkMeasures Measure.ManaValue Comparison.GreaterThan (Operand.Literal 4))
        offer = Protocol.offerOf (Setup.emptyGame S.bothPlayers) (Prompt.ChooseGuess (Decider.MkDecider S.bob) S.bob o7 proposition)
        keys = case offer of
          R.Object pairs -> fmap fst pairs
          _ -> []
    Spec.assertEqWith s "keys" keys [Text.pack "source", Text.pack "proposition"]
    Spec.assertEqWith s "source" (field "source" offer) (Just (Protocol.object o7))
    Spec.assertEqWith s "proposition" (fmap Codec.Reply.toValue (field "proposition" offer)) (Just (Codec.encode (Codec.Filter.codec Codec.Keyword.codec) proposition))

  Spec.it s "CR 118.12 an offer to pay names the cost and what offers it" $ do
    vane <- S.printingOf s registry "Arcum's Weathervane"
    let (oid, gs) = S.addPermanent vane S.alice (Setup.emptyGame S.bothPlayers)
        costs = fmap ActivatedAbility.cost (Projection.abilitiesOf oid gs)
        offers = [Protocol.offerOf gs (Prompt.ChooseToPay (Decider.MkDecider S.bob) S.bob oid (PayOffer.AtClause (ModeIndex.MkModeIndex 0) (ClauseIndex.MkClauseIndex 0)) cost mempty) | cost <- costs]
        decodedCost offer = fmap (\c -> Common.parse (Common.render (Codec.Reply.toValue c)) >>= Codec.decode (Codec.Cost.codec Codec.Keyword.codec)) (field "cost" offer)
    Spec.assertEqWith s "cost" (fmap decodedCost offers) (fmap (Just . Right) costs)
    Spec.assertEqWith s "source" (fmap (field "source") offers) (fmap (const (Just (Protocol.object oid))) costs)

  Spec.it s "a hidden card reaches no line sent to the other seat" $ do
    gs <- started s registry
    let logged = State.execState (Driver.drive [observer] (Protocol.over (exchanging client) chance) 10000 (pure . (>= 5) . GameState.turnNumber) gs) []
        sent = linesWithState logged
        to pid = [(at, line) | (at, line) <- sent, fmap (Question.seat . Request.question) (requestOf line) == Just pid]
        leaks (at, line) =
          let hidden = hiddenOf S.alice at
              names = Set.unions (fmap (`Projection.namesOf` at) hidden) `Set.difference` seenBy S.bob at
           in any (\name -> Text.unpack (CardName.unwrap name) `List.isInfixOf` line) (Set.toList names)
                || any (\oid -> ("\"$" <> show (ObjectId.unwrap oid) <> "\"") `List.isInfixOf` line) hidden
    Spec.assertBool s (not (null (to S.alice))) "alice asked"
    Spec.assertBool s (not (null (to S.bob))) "bob asked"
    Spec.assertBool s (not (any leaks (to S.bob))) "no leak"
  Spec.it s "a prompt no seat answers is never sent" $ do
    Spec.assertBool s (Maybe.isNothing (Protocol.questionOf S.threePlayerGame (Prompt.Shuffle [ObjectId.MkObjectId 7, ObjectId.MkObjectId 8]))) "shuffle"
    Spec.assertBool s (Maybe.isNothing (Protocol.questionOf S.threePlayerGame (Prompt.RollDie 6))) "die"
  Spec.it s "a reply that cannot be read is asked again with the problem" $ do
    gs <- started s registry
    let garbled = State.execState (Driver.drive [observer] (Protocol.over (exchanging once) chance) 10000 (pure . (>= 3) . GameState.turnNumber) gs) []
        problems = fmap (fmap Request.problem . requestOf . snd) (linesWithState garbled)
    case problems of
      first : second : _ -> do
        Spec.assertEqWith s "first" first (Just Nothing)
        Spec.assertBool s (maybe False Maybe.isJust second) "second"
      _ -> Spec.assertFailure s "fewer than two lines"

  Spec.it s "an answer naming what the prompt does not offer is asked again" $ do
    gs <- started s registry
    let strayed = State.execState (Driver.drive [observer] (Protocol.over (exchanging stray) chance) 10000 (pure . (>= 3) . GameState.turnNumber) gs) []
        discards = [Request.problem request | Just request <- fmap (requestOf . snd) (linesWithState strayed), Question.kind (Request.question request) == Text.pack "ChooseDiscard"]
    case discards of
      first : second : _ -> do
        Spec.assertEqWith s "first" first Nothing
        Spec.assertBool s (Maybe.isJust second) "second"
      _ -> Spec.assertFailure s "fewer than two discard lines"

-- Every prompt's state before its answer, and every line sent, in order.
type Log = [Either GameState.GameState String]

observer :: Observer.Observer (State.State Log)
observer =
  Observer.MkObserver
    { Observer.before = \asked -> State.modify' (<> [Left (Asked.game asked)]),
      Observer.after = \_ _ -> pure ()
    }

-- Sends a line to a client that answers from that line alone.
exchanging :: (Text.Text -> State.State Log Text.Text) -> Text.Text -> State.State Log Text.Text
exchanging answer line = State.modify' (<> [Right (Text.unpack line)]) >> answer line

-- Chance and the interpreter's prompts, answered as a recording would be.
chance :: Answerer.Answerer (State.State Log)
chance = Answerer.MkAnswerer (pure . Replay.defaultAnswer . Asked.prompt)

-- Answers "nonsense" to the first line it is sent, then as `client` does.
once :: Text.Text -> State.State Log Text.Text
once line = do
  sent <- State.gets (length . Either.rights)
  if sent == 1 then pure (Text.pack "nonsense") else client line

-- Discards a card that does not exist the first time it is asked to discard,
-- then answers as `client` does.
stray :: Text.Text -> State.State Log Text.Text
stray line = do
  asked <- State.gets (length . filter (Text.isInfixOf (Text.pack "\"kind\":\"ChooseDiscard\"") . Text.pack) . Either.rights)
  if asked == 1 && Text.isInfixOf (Text.pack "\"kind\":\"ChooseDiscard\"") line then pure (Text.pack "[\"$9999\"]") else client line

-- Passes, keeps, declines and discards the first cards offered, reading only
-- the line.
client :: Text.Text -> State.State Log Text.Text
client line = case requestOf (Text.unpack line) of
  Nothing -> error ("unreadable line: " <> Text.unpack line)
  Just request ->
    let question = Request.question request
        offer = Question.offer question
     in pure . Common.render . Codec.Reply.toValue $ case Text.unpack (Question.kind question) of
          "Concede" -> R.Text (Text.pack "Continues")
          "DeclareMulligan" -> R.Text (Text.pack "Keep")
          "ChooseAction" -> case offer of
            R.Array actions -> maybe R.Null (R.Number . toInteger) (List.elemIndex (R.Object [(Text.pack "action", R.Text (Text.pack "Pass"))]) actions)
            _ -> R.Null
          "ChooseDiscard" -> case (field "from" offer, field "count" offer) of
            (Just (R.Array from), Just (R.Number count)) -> R.Array (List.genericTake count from)
            _ -> R.Null
          kind -> error ("unexpected prompt: " <> kind)

field :: String -> R.Reply -> Maybe R.Reply
field key reply = case reply of
  R.Object pairs -> lookup (Text.pack key) pairs
  _ -> Nothing

requestOf :: String -> Maybe Request.Request
requestOf line = Either.either (const Nothing) Just (Common.parse (Text.pack line) >>= Codec.decode Codec.Request.codec)

-- Each line sent, with the state of the game whose prompt it carries.
linesWithState :: Log -> [(GameState.GameState, String)]
linesWithState = go Nothing
  where
    go current entries = case entries of
      [] -> []
      Left gs : rest -> go (Just gs) rest
      Right line : rest -> maybe id (\gs -> ((gs, line) :)) current (go current rest)

-- A player's hand and library.
hiddenOf :: PlayerId.PlayerId -> GameState.GameState -> [ObjectId.ObjectId]
hiddenOf pid gs = Game.zoneMembers Zone.Hand pid gs <> Game.zoneMembers Zone.Library pid gs

-- Every name a seat may see: its own hand and every public zone.
seenBy :: PlayerId.PlayerId -> GameState.GameState -> Set.Set CardName.CardName
seenBy pid gs =
  let public = [Game.zoneMembers zone owner gs | owner <- [S.alice, S.bob], zone <- [Zone.Battlefield, Zone.Graveyard, Zone.Exile, Zone.Stack]]
   in Set.unions (fmap (`Projection.namesOf` gs) (Game.zoneMembers Zone.Hand pid gs <> concat public))

redGreen :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck))
redGreen s registry = do
  red <- Cards.redDeck (S.printingOf s registry)
  green <- Cards.greenDeck (S.printingOf s registry)
  pure ((S.alice, red) NonEmpty.:| [(S.bob, green)])

-- A game after setup: alice red, bob green, hands drawn.
started :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m GameState.GameState
started s registry = do
  matchup <- redGreen s registry
  pure (snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)))
