{-# LANGUAGE GADTs #-}

-- | The line protocol: each prompt a seat answers goes out as one JSON line
-- (a 'Request.Request') and its answer comes back as one, read through
-- 'Reply.shapeOf'. An object is spelled @"$"@ and its id, a player by its id.
module Parun.Play.Protocol where

import qualified Data.Bifunctor as Bifunctor
import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Codec.CombatDamageOption as Codec.CombatDamageOption
import qualified Parun.Codec.Cost as Codec.Cost
import qualified Parun.Codec.Facing as Codec.Facing
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Codec.ManaCost as Codec.ManaCost
import qualified Parun.Codec.ManaType as Codec.ManaType
import qualified Parun.Codec.Reference as Codec.Reference
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Codec.Request as Codec.Request
import qualified Parun.Codec.SlotName as Codec.SlotName
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.PlayerView as PlayerView
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Extra.Natural as Natural
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Scenario as Scenario
import qualified Parun.Scenario.Prompt as Scenario.Prompt
import qualified Parun.Scenario.Reply as Reply
import qualified Parun.Types.Action as Action
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Label as Label
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.MulliganOffer as MulliganOffer
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Request as Request
import qualified Text.Read as Read

-- | Answers each prompt a seat answers over the line `send` carries, asking
-- again with the problem until the reply reads and is on offer; every other
-- prompt goes to `fallback`.
over :: (Monad m) => (Text.Text -> m Text.Text) -> Answerer.Answerer m -> Answerer.Answerer m
over send fallback = Answerer.MkAnswerer $ \asked -> case requestFor asked of
  Nothing -> Answerer.unwrap fallback asked
  Just request ->
    let go pending = do
          line <- send (render pending)
          either (\problem -> go pending {Request.problem = Just problem}) pure $
            Common.parse line >>= Codec.Reply.fromValue >>= decodeAnswer (Asked.prompt asked) >>= onOffer (Asked.prompt asked)
     in go request

-- | An answer the prompt offers. The engine reads one it does not with a
-- fallback of its own, which would choose for the player.
onOffer :: Prompt.Prompt r -> r -> Either Text.Text r
onOffer prompt answer
  | Scenario.withinOffer prompt answer = Right answer
  | otherwise = Left (Text.pack "not an answer the prompt offers")

-- | One line: no newline inside it, and none after.
render :: Request.Request -> Text.Text
render = Common.render . Codec.encode Codec.Request.codec

-- | What the seat answering this prompt is sent, or Nothing for a prompt no
-- seat answers.
requestFor :: Asked.Asked r -> Maybe Request.Request
requestFor asked =
  fmap
    (\question -> Request.MkRequest (Just (PlayerView.viewFor (Question.seat question) (Asked.game asked))) question Nothing)
    (questionOf (Asked.game asked) (Asked.prompt asked))

questionOf :: GameState.GameState -> Prompt.Prompt r -> Maybe Question.Question
questionOf gs prompt =
  fmap
    (\seat -> Question.MkQuestion seat (Scenario.Prompt.kindOf prompt) (offerOf gs prompt))
    (Driver.deciderOf prompt)

decodeAnswer :: Prompt.Prompt r -> R.Reply -> Either Text.Text r
decodeAnswer prompt = resolve . Reply.decode (Reply.shapeOf prompt)

encodeAnswer :: Prompt.Prompt r -> r -> R.Reply
encodeAnswer prompt = Reply.encode (Reply.shapeOf prompt) namer

namer :: Reply.Namer
namer =
  Reply.MkNamer
    (Reference.Labelled . Label.MkLabel . Text.pack . show . ObjectId.unwrap)
    (Label.MkLabel . Text.pack . show . PlayerId.unwrap)

resolve :: Reply.Needs a -> Either Text.Text a
resolve needs = case needs of
  Reply.Done a -> Right a
  Reply.Failed problem -> Left problem
  Reply.NeedObject reference k -> case reference of
    Reference.Labelled label | Just n <- idOf label -> resolve (k (ObjectId.MkObjectId n))
    _ -> Left (Text.pack "expected $ and an object's id but got " <> Codec.Reference.toText reference)
  Reply.NeedPlayer label k -> case idOf label of
    Just n -> resolve (k (PlayerId.MkPlayerId n))
    Nothing -> Left (Text.pack "expected a player's id but got " <> Label.unwrap label)

idOf :: Label.Label -> Maybe Natural
idOf label =
  let t = Label.unwrap label
   in if not (Text.null t) && Text.all Char.isDigit t then Read.readMaybe (Text.unpack t) else Nothing

-- | What a prompt offers, in its answer's vocabulary, with what the game
-- tells the seat about each option.
--
-- Not implemented: the offer of every prompt not listed here, which sends
-- null (#5225).
offerOf :: GameState.GameState -> Prompt.Prompt r -> R.Reply
offerOf gs prompt = case prompt of
  Prompt.ChooseAction _ _ offered -> R.Array (fmap (actionOffer gs) offered)
  Prompt.DeclareMulligan _ _ offer ->
    fields [("taken", natural (MulliganOffer.taken offer)), ("bottom", natural (MulliganOffer.bottomCount offer))]
  Prompt.Bottom _ _ from count -> fields [("from", objects from), ("count", natural count)]
  Prompt.ChooseDiscard _ _ from count -> fields [("from", objects from), ("count", natural count)]
  Prompt.DeclareAttackers _ _ attackers -> objects attackers
  Prompt.DeclareBlockers _ _ blockers attackers -> fields [("blockers", objects blockers), ("attackers", objects attackers)]
  Prompt.ChooseTargets _ _ source slots ->
    fields
      [ ("source", object source),
        ("slots", Reply.encode (Reply.mapOf (Reply.viaCodec Codec.SlotName.codec) (Reply.pairOf Reply.natural (Reply.setOf Reply.recipient))) namer slots)
      ]
  Prompt.ChooseManaSource _ payer cost sources ->
    fields [("payer", Reply.encode Reply.player namer payer), ("cost", Reply.encode (Reply.viaCodec Codec.ManaCost.codec) namer cost), ("sources", manaSources gs sources)]
  Prompt.ChooseExtraManaSource _ _ sources -> fields [("sources", manaSources gs sources)]
  Prompt.ChooseManaYield _ _ source options -> fields [("source", object source), ("yields", Reply.encode (Reply.list (Reply.list (Reply.viaCodec Codec.ManaType.codec))) namer (fmap (fmap ManaUnit.manaType . Mana.yieldUnits) (Foldable.toList options)))]
  Prompt.ChooseX _ _ source variable least greatest -> fields [("source", object source), ("variable", Reply.encode (Reply.viaCodec Codec.SlotName.codec) namer variable), ("least", natural least), ("greatest", natural greatest)]
  Prompt.ChooseOptional _ _ source _ _ _ -> fields [("source", object source)]
  Prompt.AssignCombatDamage _ _ source lethal total ->
    fields [("source", object source), ("lethal", Reply.encode (Reply.mapOf Reply.recipient Reply.natural) namer lethal), ("total", natural total)]
  Prompt.ChooseCombatDamageOption _ _ source option -> fields [("source", object source), ("option", Reply.encode (Reply.viaCodec Codec.CombatDamageOption.codec) namer option)]
  Prompt.ChooseToPay _ _ source _ cost _ -> fields [("source", object source), ("cost", Reply.encode (Reply.viaCodec (Codec.Cost.codec Codec.Keyword.codec)) namer cost)]
  Prompt.ChooseDivision _ _ source dividing targets ->
    fields
      ( [("source", object source), ("targets", Reply.encode (Reply.list Reply.recipient) namer (NonEmpty.toList targets))]
          <> case dividing of
            Dividing.Total total -> [("total", natural total)]
            Dividing.Parts parts -> [("parts", Reply.encode (Reply.list Reply.natural) namer (NonEmpty.toList parts))]
      )
  _ -> R.Null

-- | An action as an offer names it: its constructor, the object it acts on,
-- the face or half it names, and for an Activate, the ability's place among
-- its source's (Projection.abilitiesOf, as a scenario's Activation names it).
actionOffer :: GameState.GameState -> Action.Action -> R.Reply
actionOffer gs action = fields (("action", R.Text (Text.pack kind)) : rest)
  where
    (kind, rest) = case action of
      Action.Pass -> ("Pass", [])
      Action.Play oid name -> ("Play", on oid <> foldMap named name)
      Action.Cast oid name facing -> ("Cast", on oid <> named name <> [("facing", Reply.encode (Reply.viaCodec Codec.Facing.codec) namer facing)])
      Action.Activate oid ability -> ("Activate", on oid <> [("ability", natural (Natural.length (takeWhile (/= ability) abilities))) | let abilities = Projection.abilitiesOf oid gs, ability `elem` abilities])
      Action.ActivateManaAbility oid -> ("ActivateManaAbility", on oid)
      Action.TurnFaceUp oid _ -> ("TurnFaceUp", on oid)
      Action.TurnConspiracyFaceUp oid -> ("TurnConspiracyFaceUp", on oid)
      Action.Unlock oid name -> ("Unlock", on oid <> named name)
      Action.DiscardFromHand oid -> ("DiscardFromHand", on oid)
      Action.Ignore oid _ -> ("Ignore", on oid)
      Action.Plot oid _ -> ("Plot", on oid)
      Action.Foretell oid -> ("Foretell", on oid)
      Action.Suspend oid -> ("Suspend", on oid)
      Action.PutCompanionIntoHand -> ("PutCompanionIntoHand", [])
      Action.EndEffect oid -> ("EndEffect", on oid)
      Action.RollPlanarDie -> ("RollPlanarDie", [])
    on oid = [("object", object oid)]
    named name = [("name", R.Text (CardName.unwrap name))]

-- | Each mana source beside the mana it could make, one list of mana types
-- per yield (Mana.manaYieldsOf).
manaSources :: GameState.GameState -> NonEmpty.NonEmpty ObjectId.ObjectId -> R.Reply
manaSources gs sources =
  R.Array
    [ fields [("source", object oid), ("makes", Reply.encode (Reply.list (Reply.list (Reply.viaCodec Codec.ManaType.codec))) namer (fmap (fmap ManaUnit.manaType . Mana.Type.unwrap) (Mana.manaYieldsOf oid gs)))]
    | oid <- Foldable.toList sources
    ]

fields :: [(String, R.Reply)] -> R.Reply
fields = R.Object . fmap (Bifunctor.first Text.pack)

object :: ObjectId.ObjectId -> R.Reply
object = Reply.encode Reply.object namer

objects :: [ObjectId.ObjectId] -> R.Reply
objects = Reply.encode (Reply.list Reply.object) namer

natural :: Natural -> R.Reply
natural = Reply.encode Reply.natural namer

-- | CR 103.1: whether this seat plays first rather than draws, asked over the
-- line before the game begins, so with no view; asked again with the problem
-- until the reply is Play or Draw. Nothing at the end of input.
playOrDraw :: (Monad m) => (Text.Text -> m (Maybe Text.Text)) -> PlayerId.PlayerId -> m (Maybe Bool)
playOrDraw send seat = go Nothing
  where
    choices = [(Text.pack "Play", True), (Text.pack "Draw", False)]
    question = Question.MkQuestion seat (Text.pack "PlayOrDraw") (R.Array (fmap (R.Text . fst) choices))
    go problem = do
      line <- send (render (Request.MkRequest Nothing question problem))
      case fmap (\l -> Common.parse l >>= Codec.Reply.fromValue >>= chosen) line of
        Nothing -> pure Nothing
        Just (Right plays) -> pure (Just plays)
        Just (Left again) -> go (Just again)
    chosen reply = case reply of
      R.Text word | Just plays <- lookup word choices -> Right plays
      _ -> Left (Text.pack "expected Play or Draw")
