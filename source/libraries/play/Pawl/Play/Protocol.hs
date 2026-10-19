{-# LANGUAGE GADTs #-}

-- | The line protocol: each prompt a seat answers goes out as one JSON line
-- (a 'Request.Request') and its answer comes back as one, read through
-- 'Reply.shapeOf'. An object is spelled @"$"@ and its id, a player by its id.
module Pawl.Play.Protocol where

import qualified Data.Bifunctor as Bifunctor
import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Codec.Facing as Codec.Facing
import qualified Pawl.Codec.ManaCost as Codec.ManaCost
import qualified Pawl.Codec.ManaType as Codec.ManaType
import qualified Pawl.Codec.Reference as Codec.Reference
import qualified Pawl.Codec.Reply as Codec.Reply
import qualified Pawl.Codec.Request as Codec.Request
import qualified Pawl.Codec.SlotName as Codec.SlotName
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Engine.Mana as Mana
import qualified Pawl.Engine.PlayerView as PlayerView
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Scenario.Prompt as Scenario.Prompt
import qualified Pawl.Scenario.Reply as Reply
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.Mana as Mana.Type
import qualified Pawl.Types.ManaUnit as ManaUnit
import qualified Pawl.Types.MulliganOffer as MulliganOffer
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Question as Question
import qualified Pawl.Types.Reference as Reference
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.Request as Request
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
    (\question -> Request.MkRequest (PlayerView.viewFor (Question.seat question) (Asked.game asked)) question Nothing)
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
  Prompt.ChooseAction _ _ offered -> R.Array (fmap actionOffer offered)
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
  Prompt.ChooseX _ _ source least greatest -> fields [("source", object source), ("least", natural least), ("greatest", natural greatest)]
  Prompt.ChooseOptional _ _ source _ _ _ -> fields [("source", object source)]
  _ -> R.Null

-- | An action as an offer names it: its constructor, the object it acts on,
-- and the face or half it names.
--
-- Not implemented: which of its source's abilities an Activate names (#5225).
actionOffer :: Action.Action -> R.Reply
actionOffer action = fields (("action", R.Text (Text.pack kind)) : rest)
  where
    (kind, rest) = case action of
      Action.Pass -> ("Pass", [])
      Action.Play oid name -> ("Play", on oid <> foldMap named name)
      Action.Cast oid name facing -> ("Cast", on oid <> named name <> [("facing", Reply.encode (Reply.viaCodec Codec.Facing.codec) namer facing)])
      Action.Activate oid _ -> ("Activate", on oid)
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
