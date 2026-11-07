{-# LANGUAGE GADTs #-}

-- | The line protocol: each prompt a seat answers goes out as one JSON line
-- (a 'Request.Request') and its answer comes back as one, read through
-- 'Reply.shapeOf'. An object is spelled @"$"@ and its id, a player by its id.
module Parun.Play.Protocol where

import qualified Data.Bifunctor as Bifunctor
import qualified Data.Char as Char
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Codec.CombatDamageOption as Codec.CombatDamageOption
import qualified Parun.Codec.Cost as Codec.Cost
import qualified Parun.Codec.Facing as Codec.Facing
import qualified Parun.Codec.Filter as Codec.Filter
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Codec.ManaCost as Codec.ManaCost
import qualified Parun.Codec.ManaSymbol as Codec.ManaSymbol
import qualified Parun.Codec.ManaType as Codec.ManaType
import qualified Parun.Codec.ManaUnit as Codec.ManaUnit
import qualified Parun.Codec.NumberFloor as Codec.NumberFloor
import qualified Parun.Codec.Reference as Codec.Reference
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Codec.Request as Codec.Request
import qualified Parun.Codec.SlotName as Codec.SlotName
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.PlayerView as PlayerView
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection.View
import qualified Parun.Extra.Natural as Natural
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Oracle as Oracle
import qualified Parun.Play.Render as Render
import qualified Parun.Scenario as Scenario
import qualified Parun.Scenario.Prompt as Scenario.Prompt
import qualified Parun.Scenario.Reply as Reply
import qualified Parun.Types.Action as Action
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.BallotChoice as BallotChoice
import qualified Parun.Types.CandidateCost as CandidateCost
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.Label as Label
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.MulliganOffer as MulliganOffer
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Request as Request
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.TriggerEntry as TriggerEntry
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Text.Read as Read

-- | Answers each prompt a seat answers over the line `send` carries, asking
-- again with the problem until the reply reads and is on offer; every other
-- prompt goes to `fallback`.
over :: (Monad m) => (Text.Text -> m Text.Text) -> Answerer.Answerer (Asked.Asked GameState.GameState) m -> Answerer.Answerer (Asked.Asked GameState.GameState) m
over send fallback = Answerer.MkAnswerer $ \asked -> case requestFor asked of
  Nothing -> Answerer.unwrap fallback asked
  Just request ->
    let go pending = do
          line <- send (render pending)
          either (\problem -> go pending {Request.problem = Just problem}) pure $
            Common.parse line >>= Codec.Reply.fromValue >>= decodeAnswer (Asked.prompt asked) >>= onOffer (Asked.prompt asked) >>= lawful named (Asked.game asked) (Asked.prompt asked)
        named = maybe (const (Text.pack "a creature")) Render.named (Request.view request)
     in go request

-- | An answer the prompt offers. The engine reads one it does not with a
-- fallback of its own, which would choose for the player.
onOffer :: Prompt.Prompt r -> r -> Either Text.Text r
onOffer prompt answer
  | Scenario.withinOffer prompt answer = Right answer
  | otherwise = Left (Text.pack "not an answer the prompt offers")

-- | An answer the rules let stand: an illegal declaration of attackers (CR
-- 508.1c, 508.1d) or blockers (CR 509.1b, 509.1c) is refused with why, where
-- the engine's rewind would ask again with no reason and degrade a repeat to a
-- declaration the player did not make. ProtocolSpec's Wind Drake and Bonded
-- Construct cases are the proof.
--
-- Not implemented: refusing an illegal declaration of attackers where more than
-- one attack target is declarable, whose CR 508.1b announcements follow this
-- answer (#6291).
lawful :: (ObjectId.ObjectId -> Text.Text) -> GameState.GameState -> Prompt.Prompt r -> r -> Either Text.Text r
lawful named gs prompt answer = case prompt of
  Prompt.DeclareAttackers _ pid _
    | [target] <- Combat.declarableTargets gs,
      not (Combat.attackProposalAllowed pid (Map.fromList (fmap (\oid -> (oid, target)) answer)) gs) ->
        Left (Text.pack "the declaration of attackers is illegal")
  Prompt.DeclareBlockers _ pid _ _
    | not (Combat.legalBlockDeclaration pid answer gs) ->
        Left (Text.pack "the declaration of blockers is illegal" <> foldMap (\(blocker, attacker) -> Text.pack ": " <> named blocker <> Text.pack " can't block " <> named attacker) (Maybe.listToMaybe (Combat.forbiddenBlocks pid answer gs)))
  _ -> Right answer

-- | One line: no newline inside it, and none after.
render :: Request.Request -> Text.Text
render = Common.render . Codec.encode Codec.Request.codec

-- | What the seat answering this prompt is sent, or Nothing for a prompt no
-- seat answers.
requestFor :: Asked.Asked GameState.GameState r -> Maybe Request.Request
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
  -- CR 404.3: the batch, from the top down as it would land.
  Prompt.ArrangeGraveyardArrivals _ _ batch -> fields [("from", objects batch)]
  Prompt.DeclareAttackers _ _ attackers -> objects attackers
  Prompt.DeclareBlockers _ _ blockers attackers -> fields [("blockers", objects blockers), ("attackers", objects attackers)]
  Prompt.DividePiles _ _ creatures count -> fields [("from", objects creatures), ("count", natural count)]
  Prompt.ChooseTargets _ _ source slots ->
    fields
      [ ("source", object source),
        ("slots", Reply.encode (Reply.mapOf (Reply.viaCodec Codec.SlotName.codec) (Reply.pairOf Reply.natural (Reply.setOf Reply.recipient))) namer slots)
      ]
  Prompt.ChooseManaSource _ payer cost sources ->
    fields
      ( [("payer", Reply.encode Reply.player namer payer), ("cost", Reply.encode (Reply.viaCodec Codec.ManaCost.codec) namer cost), ("sources", manaSources gs sources)]
          <> [("substitutes", Reply.encode (Reply.list (Reply.viaCodec Codec.Keyword.codec)) namer keywords) | let keywords = substitutingKeywords gs payer cost, not (null keywords)]
      )
  Prompt.ChooseExtraManaSource _ _ sources -> fields [("sources", manaSources gs sources)]
  -- CR 734.1: the sources of the one activation asked about.
  Prompt.ReverseManaAbilities _ _ sources -> fields [("sources", objects (NonEmpty.toList sources))]
  -- CR 601.2b / 702.51a: each candidate's cost.
  --
  -- Not implemented: the keyword that offered each candidate (#5225).
  Prompt.ChooseCost _ _ source candidates _ -> fields [("source", object source), ("costs", Reply.encode (Reply.list (Reply.viaCodec (Codec.Cost.codec Codec.Keyword.codec))) namer (fmap CandidateCost.cost candidates))]
  Prompt.PayLifeForMana _ _ life mana -> fields [("life", natural life), ("mana", Reply.encode (Reply.viaCodec Codec.ManaType.codec) namer mana)]
  Prompt.ChooseManaYield _ _ source options -> fields [("source", object source), ("yields", Reply.encode (Reply.list (Reply.list (Reply.viaCodec Codec.ManaType.codec))) namer (fmap (fmap ManaUnit.manaType . Mana.yieldUnits) (Foldable.toList options)))]
  Prompt.ChooseManaSpentOnX _ _ source shares -> fields [("source", object source), ("shares", Reply.encode (Reply.list (Reply.list (Reply.viaCodec Codec.ManaType.codec))) namer (fmap (fmap ManaUnit.manaType . Mana.Type.unwrap) (Foldable.toList shares)))]
  Prompt.ChooseX _ _ source variable least greatest -> fields [("source", object source), ("variable", Reply.encode (Reply.viaCodec Codec.SlotName.codec) namer variable), ("least", natural least), ("greatest", natural greatest)]
  Prompt.ChooseNumber _ _ source least meaning most -> fields ([("source", object source), ("least", natural least), ("floor", Reply.encode (Reply.viaCodec Codec.NumberFloor.codec) namer meaning)] <> [("greatest", natural greatest) | Just greatest <- [most]])
  Prompt.ChooseOptional _ _ source _ _ _ -> fields [("source", object source)]
  Prompt.ChooseGuess _ _ source proposition -> fields [("source", object source), ("proposition", Reply.encode (Reply.viaCodec (Codec.Filter.codec Codec.Keyword.codec)) namer proposition)]
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
  -- CR 603.3b / 101.4c: each entry as its source and its Oracle text.
  Prompt.OrderTriggers _ _ entries -> R.Array (fmap (triggerEntry gs) entries)
  -- CR 601.2h: each pool unit whole, as the answer names it.
  Prompt.ChooseManaToSpend _ _ units -> Reply.encode (Reply.list (Reply.viaCodec Codec.ManaUnit.codec)) namer (NonEmpty.toList units)
  -- CR 701.23a: the searcher looks at the cards searched, so each is named.
  Prompt.Search _ _ cards count -> fields [("from", objects cards), ("names", R.Array (fmap (R.Text . Render.snapshotName . (`Projection.project` gs)) cards)), ("count", natural count)]
  Prompt.ChooseConjuredCard _ _ names -> choosing prompt "options" Nothing [] (NonEmpty.toList names)
  Prompt.ChooseCoinResult _ _ faces -> choosing prompt "options" Nothing [] (NonEmpty.toList faces)
  Prompt.ChooseDefender _ _ players -> choosing prompt "players" Nothing [] (NonEmpty.toList players)
  Prompt.ChooseRingBearer _ _ candidates -> choosing prompt "options" Nothing [] (NonEmpty.toList candidates)
  Prompt.ChooseBolster _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  Prompt.ChooseAmass _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  Prompt.ChooseBlight _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  Prompt.ChooseBehold _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  -- Every choice of one vote is of one kind (Parun.Types.VoteChoices).
  Prompt.ChooseVote _ _ source choices -> choosing prompt (case NonEmpty.head choices of BallotChoice.ForPlayer _ -> "players"; _ -> "options") (Just source) [] (NonEmpty.toList choices)
  Prompt.ChooseCounterKind _ _ _ kinds -> choosing prompt "options" Nothing [] (NonEmpty.toList kinds)
  -- CR 122.5: the object the counters move off, and the one they move onto.
  Prompt.ChooseMovedCounterOrNone _ _ off onto kinds -> choosing prompt "options" Nothing [("off", object off), ("onto", object onto)] (orNone kinds)
  Prompt.ChooseDamageSource _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  -- CR 101.4b: the cards earlier choosers took, beside who took each.
  Prompt.ChooseCardInGraveyard _ _ source cards earlier -> choosing prompt "options" (Just source) [("earlier", Reply.encode (Reply.seqOf (Reply.pairOf Reply.player Reply.object)) namer earlier)] (NonEmpty.toList cards)
  Prompt.ChooseCardInHand _ _ source cards -> choosing prompt "options" (Just source) [] (NonEmpty.toList cards)
  Prompt.ChooseCardFromAmong _ _ source cards -> choosing prompt "options" (Just source) [] (NonEmpty.toList cards)
  Prompt.ChooseDungeon _ _ dungeons -> choosing prompt "options" Nothing [] (NonEmpty.toList dungeons)
  Prompt.ChooseSticker _ _ source stickers -> choosing prompt "options" (Just source) [] (NonEmpty.toList stickers)
  Prompt.ChooseStickerOrNone _ _ source stickers -> choosing prompt "options" (Just source) [] (orNone stickers)
  Prompt.ChooseNamePosition _ _ source positions -> choosing prompt "options" (Just source) [] (NonEmpty.toList positions)
  Prompt.ChooseCompanion _ _ companions -> choosing prompt "options" Nothing [] (orNone companions)
  Prompt.ChooseRoom _ _ source rooms -> choosing prompt "options" (Just source) [] (NonEmpty.toList rooms)
  Prompt.ChooseHalf _ _ source names -> choosing prompt "options" (Just source) [] (NonEmpty.toList names)
  Prompt.ChooseLegend _ _ candidates -> choosing prompt "options" Nothing [] (NonEmpty.toList candidates)
  Prompt.ChooseAttackTarget _ _ attacker targets -> choosing prompt "options" (Just attacker) [] (NonEmpty.toList targets)
  Prompt.ChooseEnlist _ _ source candidates -> choosing prompt "options" (Just source) [] (orNone candidates)
  Prompt.ChooseEncode _ _ source candidates -> choosing prompt "options" (Just source) [] (orNone candidates)
  Prompt.ChooseAssistant _ _ source players -> choosing prompt "players" (Just source) [] (orNone players)
  Prompt.ChooseCopyTarget _ _ source candidates -> choosing prompt "options" (Just source) [] (fmap Just candidates <> [Nothing])
  Prompt.ChooseRevealOnEntry _ _ source cards -> choosing prompt "options" (Just source) [] (orNone cards)
  Prompt.ChooseColor _ _ source colors -> choosing prompt "options" (Just source) [] (NonEmpty.toList colors)
  Prompt.ChooseDesignation _ _ source designations -> choosing prompt "options" (Just source) [] (NonEmpty.toList designations)
  Prompt.ChooseManaType _ _ source types -> choosing prompt "options" (Just source) [] (NonEmpty.toList types)
  Prompt.ChooseCardType _ _ source types -> choosing prompt "options" (Just source) [] (NonEmpty.toList types)
  Prompt.ChooseOpponent _ _ source _ players -> choosing prompt "players" (Just source) [] (NonEmpty.toList players)
  Prompt.ChooseProtector _ _ source players -> choosing prompt "players" (Just source) [] (NonEmpty.toList players)
  Prompt.ChoosePlayer _ _ source players -> choosing prompt "players" (Just source) [] (NonEmpty.toList players)
  Prompt.ChooseActivePlayer _ _ players -> choosing prompt "players" Nothing [] (NonEmpty.toList players)
  -- CR 101.4b: the objects earlier choosers chose, beside who chose them.
  Prompt.ChoosePermanent _ _ source candidates earlier -> choosing prompt "options" (Just source) [("earlier", Reply.encode (Reply.seqOf (Reply.pairOf Reply.player (Reply.setOf Reply.object))) namer earlier)] (NonEmpty.toList candidates)
  Prompt.ChooseCounterRemoval _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  Prompt.ChooseAttachment _ _ source candidates -> choosing prompt "options" (Just source) [] (NonEmpty.toList candidates)
  Prompt.ChooseOfferedCastSpell _ _ offers -> choosing prompt "options" Nothing [] (NonEmpty.toList offers)
  Prompt.ChoosePlayPermission _ _ source permissions -> choosing prompt "options" (Just source) [] (NonEmpty.toList permissions)
  -- CR 601.2b: the symbol announced for, beside each way to pay it.
  Prompt.AnnouncePhyrexianPayment _ _ source symbol payments -> choosing prompt "options" (Just source) [("symbol", Reply.encode (Reply.viaCodec Codec.ManaSymbol.codec) namer symbol)] (NonEmpty.toList payments)
  Prompt.AnnounceHybridPayment _ _ source mana payments -> choosing prompt "options" (Just source) [("mana", Reply.encode (Reply.viaCodec Codec.ManaType.codec) namer mana)] (NonEmpty.toList payments)
  Prompt.AnnounceHybridHalf _ _ source symbol halves -> choosing prompt "options" (Just source) [("symbol", Reply.encode (Reply.viaCodec Codec.ManaSymbol.codec) namer symbol)] (NonEmpty.toList halves)
  Prompt.ChooseReductionHalf _ _ source symbol halves -> choosing prompt "options" (Just source) [("symbol", Reply.encode (Reply.viaCodec Codec.ManaSymbol.codec) namer symbol)] (NonEmpty.toList halves)
  Prompt.ChooseReducedCost _ _ source costs -> choosing prompt "options" (Just source) [] (NonEmpty.toList costs)
  _ -> R.Null

-- | A prompt answered by one of what it lists: its source where it has one,
-- what else the seat is told, and under @key@ each option spelled as the
-- answer that picks it, @"players"@ for seats (which the line spells as bare
-- ids) and @"options"@ for anything else.
choosing :: Prompt.Prompt r -> String -> Maybe ObjectId.ObjectId -> [(String, R.Reply)] -> [r] -> R.Reply
choosing prompt key source told options =
  fields ([("source", object s) | Just s <- [source]] <> told <> [(key, R.Array (fmap (Reply.encode (Reply.shapeOf prompt) namer) options))])

-- | Each of a "may" prompt's options, then declining, spelled null.
orNone :: NonEmpty.NonEmpty a -> [Maybe a]
orNone options = fmap Just (NonEmpty.toList options) <> [Nothing]

-- | CR 603.3b: an entry of a trigger ordering as its source (null for none, CR
-- 113.7) and, where it renders, its ability's Oracle text, which tells apart
-- two abilities of one source.
triggerEntry :: GameState.GameState -> TriggerEntry.TriggerEntry -> R.Reply
triggerEntry gs entry = fields (("source", source) : [("text", R.Text text) | text <- take 1 texts])
  where
    ability = TriggerEntry.ability entry
    (source, texts) = case TriggerEntry.source entry of
      TriggerSource.OfObject oid
        | Maybe.isJust (Game.lookupObject oid gs) ->
            let c = Projection.project oid gs
             in (object oid, Oracle.triggered (Oracle.contextOf (Render.snapshotName c) []) (Set.member CardType.Creature (ProjectedCharacteristics.cardTypes c)) ability)
        | otherwise -> (object oid, [])
      TriggerSource.Sourceless -> (R.Null, Oracle.triggered (Oracle.contextOf Text.empty []) False ability)

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
      Action.EndEffect oid _ -> ("EndEffect", on oid)
      Action.MakeLaterPayment oid _ -> ("MakeLaterPayment", on oid)
      Action.PayLifeForMana life mana -> ("PayLifeForMana", [("life", natural life), ("mana", Reply.encode (Reply.viaCodec Codec.ManaType.codec) namer mana)])
      Action.RollPlanarDie -> ("RollPlanarDie", [])
    on oid = [("object", object oid)]
    named name = [("name", R.Text (CardName.unwrap name))]

-- | CR 702.51a / 702.66a / 702.126a: the keywords of the spell `payer` is
-- casting that let part of this cost be paid other than with mana, which
-- Cost.announceSubstitutions asks about once CR 601.2g's window closes. None
-- for a payment that is not a cast's: CR 601.2a put the spell on top of the
-- stack, and CR 601.2i has not yet logged it cast.
substitutingKeywords :: GameState.GameState -> PlayerId.PlayerId -> ManaCost.ManaCost -> [Keyword.Type.Keyword]
substitutingKeywords gs payer cost = case GameState.stack gs of
  top : _
    | Game.isSpell top gs,
      Projection.View.controllerOf top gs == Just payer,
      not (any (castAs top . LoggedEvent.event) (GameState.events gs)) ->
        ListUtils.nubOrd
          [ k
          | k <- Map.keys (Cost.spellKeywords payer top gs),
            symbol <- ManaCost.unwrap cost,
            not (null (Keyword.manaSubstitutesFor symbol (Set.singleton k)))
          ]
  _ -> []
  where
    castAs top e = case e of
      GameEvent.SpellCast cast -> SpellWasCast.spell cast == top
      _ -> False

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
