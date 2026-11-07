-- Covers Parun.Play.Protocol: a seat's decisions as lines out and answers back,
-- and that nothing a seat may not see reaches its lines.
module Parun.ProtocolSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Either as Either
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Cards as Cards
import qualified Parun.Codec.Cost as Codec.Cost
import qualified Parun.Codec.CostComponent as Codec.CostComponent
import qualified Parun.Codec.Filter as Codec.Filter
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Codec.Request as Codec.Request
import qualified Parun.Engine.Combat as Combat
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
import qualified Parun.Scenario as Scenario
import qualified Parun.Scenario.Prompt as Scenario.Prompt
import qualified Parun.Scenario.Reply as Reply
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Action as Action
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Combat as Combat.Type
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.Game as Game.Type
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GraveyardArrangement as GraveyardArrangement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PayOffer as PayOffer
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Request as Request
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Undoing as Undoing
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Protocol" $ do
  Spec.it s "every answer in ten turns of a game survives the protocol's encode and decode" $ do
    matchup <- redGreen s registry
    let checking :: Answerer.Answerer (Asked.Asked GameState.GameState) (State.State [(Text.Text, Bool)])
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

  Spec.it s "CR 404.3 a graveyard batch offers its cards top first, and an arrangement reads back" $ do
    let o5 = ObjectId.MkObjectId 5
        o7 = ObjectId.MkObjectId 7
        prompt = Prompt.ArrangeGraveyardArrivals (Decider.MkDecider S.alice) S.alice [o7, o5]
        offer = Protocol.offerOf (Setup.emptyGame S.bothPlayers) prompt
    Spec.assertEqWith s "from" (field "from" offer) (Just (Protocol.objects [o7, o5]))
    Spec.assertEqWith s "in order" (Protocol.decodeAnswer prompt (R.Array [R.Number 1, R.Number 0])) (Right (GraveyardArrangement.InOrder [1, 0]))
    Spec.assertEqWith s "any order" (Protocol.decodeAnswer prompt R.Null) (Right GraveyardArrangement.AnyOrder)

  Spec.it s "a prompt answered by one of a list offers each option as the answer that picks it" $ do
    let o7 = ObjectId.MkObjectId 7
        o9 = ObjectId.MkObjectId 9
        o11 = ObjectId.MkObjectId 11
        alice = Decider.MkDecider S.alice
        gs = Setup.emptyGame S.bothPlayers
        listed key prompt = do
          let offer = Protocol.offerOf gs prompt
          options <- maybe (Left (Text.pack ("no " <> key))) Right (field key offer >>= arrayOf)
          answers <- traverse (Protocol.decodeAnswer prompt) options
          pure (field "source" offer, answers)
        hand = Prompt.ChooseCardInHand alice S.alice o7 (o9 NonEmpty.:| [o11])
    Spec.assertEqWith s "cards" (listed "options" hand) (Right (Just (Protocol.object o7), [o9, o11]))
    Spec.assertEqWith s "players" (listed "players" (Prompt.ChoosePlayer alice S.alice o7 (S.alice NonEmpty.:| [S.bob]))) (Right (Just (Protocol.object o7), [S.alice, S.bob]))
    Spec.assertEqWith s "a may declines last" (listed "players" (Prompt.ChooseAssistant alice S.alice o7 (S.bob NonEmpty.:| []))) (Right (Just (Protocol.object o7), [Just S.bob, Nothing]))
    Spec.assertEqWith s "words" (listed "options" (Prompt.ChooseColor alice S.alice o7 (Color.Red NonEmpty.:| [Color.Green]))) (Right (Just (Protocol.object o7), [Color.Red, Color.Green]))
    Spec.assertEqWith s "attack targets" (listed "options" (Prompt.ChooseAttackTarget alice S.alice o7 (AttackTarget.OfPlayer S.bob NonEmpty.:| [AttackTarget.OfPlaneswalker o9]))) (Right (Just (Protocol.object o7), [AttackTarget.OfPlayer S.bob, AttackTarget.OfPlaneswalker o9]))
    Spec.assertEqWith s "no source" (listed "players" (Prompt.ChooseActivePlayer alice S.alice (S.bob NonEmpty.:| [S.alice]))) (Right (Nothing, [S.bob, S.alice]))
    Spec.assertBool s (all (Scenario.withinOffer hand) [o9, o11]) "every option within the offer"
    -- CR 101.4b: what earlier choosers took.
    let graveyard = Protocol.offerOf gs (Prompt.ChooseCardInGraveyard alice S.alice o7 (o9 NonEmpty.:| []) (Seq.singleton (S.bob, o11)))
    Spec.assertEqWith s "earlier" (field "earlier" graveyard) (Just (R.Array [R.Array [R.Text (Text.pack "1"), Protocol.object o11]]))

  Spec.it s "CR 401.4 a prompt answered by a permutation offers each item it orders, and every permutation is within the offer" $ do
    giant <- S.printingOf s registry "Hill Giant"
    let o7 = ObjectId.MkObjectId 7
        o9 = ObjectId.MkObjectId 9
        o11 = ObjectId.MkObjectId 11
        alice = Decider.MkDecider S.alice
        (printing, gs) = Game.intern giant (Setup.emptyGame S.bothPlayers)
        offerOf = Protocol.offerOf gs
        both = Just (R.Array [Protocol.object o9, Protocol.object o11])
        components = [CostComponent.TapThis, CostComponent.SacrificeThis]
        hit = DamageEvent.MkDamageEvent o7 (Recipient.ToPlayer S.bob) 2 False False False 0 Nothing Nothing mempty False mempty DamageKind.Noncombat
        arrivals = Prompt.ArrangeLibraryArrivals alice S.alice LibraryPosition.Bottom [o9, o11]
        cost = Prompt.OrderCostComponents alice S.alice o7 components
        cards = Prompt.OrderComponentCards alice S.alice Zone.Graveyard [printing, printing]
        each = Prompt.OrderForEach alice S.alice o7 [Recipient.ToCreature o9, Recipient.ToPlayer S.bob]
    Spec.assertEqWith s "library cards" (field "order" (offerOf (Prompt.ArrangeLibraryCards alice S.alice [o9, o11]))) both
    Spec.assertEqWith s "library arrivals, beside their end" (fmap (\key -> field key (offerOf arrivals)) ["end", "order"]) [Just (R.Text (Text.pack "Bottom")), both]
    Spec.assertEqWith s "timestamps" (field "order" (offerOf (Prompt.OrderTimestamps alice S.alice [o9, o11]))) both
    Spec.assertEqWith s "mana activations" (field "order" (offerOf (Prompt.OrderManaActivations alice S.alice [o9, o11]))) both
    Spec.assertEqWith s "combat tolls" (field "order" (offerOf (Prompt.OrderCombatTolls alice S.alice [o9, o11]))) both
    Spec.assertEqWith s "component cards by name, beside their zone" (fmap (\key -> field key (offerOf cards)) ["zone", "order"]) [Just (R.Text (Text.pack "Graveyard")), Just (R.Array (replicate 2 (R.Text (Text.pack "Hill Giant"))))]
    Spec.assertEqWith s "cost components, beside their source" (field "source" (offerOf cost), fmap (traverse (either (const Nothing) Just . Codec.decode (Codec.CostComponent.codec Codec.Keyword.codec) . Codec.Reply.toValue)) (field "order" (offerOf cost) >>= arrayOf)) (Just (Protocol.object o7), Just (Just components))
    Spec.assertEqWith s "damage events" (field "order" (offerOf (Prompt.OrderDamage alice S.alice [hit]))) (Just (R.Array [R.Object [(Text.pack "source", Protocol.object o7), (Text.pack "target", R.Array [R.Text (Text.pack "Player"), R.Text (Text.pack "1")]), (Text.pack "amount", R.Number 2)]]))
    Spec.assertEqWith s "recipients, beside their source" (field "source" (offerOf each), field "order" (offerOf each)) (Just (Protocol.object o7), Just (Reply.encode (Reply.list Reply.recipient) Protocol.namer [Recipient.ToCreature o9, Recipient.ToPlayer S.bob]))
    Spec.assertBool s (all (Scenario.withinOffer arrivals) [[0, 1], [1, 0]] && not (Scenario.withinOffer arrivals [0, 0])) "each permutation within the offer, and only those"

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

  Spec.it s "CR 734.1 a seat's view says why its cast was reversed, until it chooses its next action" $ do
    gs <- started s registry
    bears <- S.printingOf s registry "Grizzly Bears"
    forest <- S.printingOf s registry "Forest"
    let (_, g1) = S.addPermanent forest S.alice gs
        (_, g2) = S.addPermanent forest S.alice g1
        board = snd (S.addHandCard bears S.alice g2)
        logged = State.execState (Driver.drive [observer] (Protocol.over (exchanging stopsOnce) chance) 10000 (pure . (>= 4) . GameState.turnNumber) board) []
        sent = fmap snd (linesWithState logged)
        afterStop = drop 1 (dropWhile (not . List.isInfixOf "\"kind\":\"ChooseManaSource\"") sent)
        undone = [PlayerView.undone view | Just request <- fmap requestOf afterStop, Question.seat (Request.question request) == S.alice, Question.kind (Request.question request) == Text.pack "ChooseAction", Just view <- [Request.view request]]
    case undone of
      next : later -> do
        Spec.assertEqWith s "the next priority says the cost was not paid" next (Just Undoing.UnpaidCost)
        Spec.assertBool s (not (null later)) "alice is asked again"
        Spec.assertEqWith s "and no later one says anything" (filter Maybe.isJust later) []
      [] -> Spec.assertFailure s "alice never stopped a payment"

  Spec.it s "CR 205.3e a subtype of the wrong kind is refused and asked again" $ do
    gs <- started s registry
    let oid = ObjectId.MkObjectId 1
        creature = Prompt.ChooseCreatureType (Decider.MkDecider S.alice) S.alice oid
        basicLand = Prompt.ChooseBasicLandType (Decider.MkDecider S.alice) S.alice oid
        replies = [Protocol.encodeAnswer creature Subtype.Island, Protocol.encodeAnswer creature Subtype.Goblin, Protocol.encodeAnswer basicLand Subtype.Goblin, Protocol.encodeAnswer basicLand Subtype.Swamp]
        ((chosen, _), sent) = overTheLine replies gs ((,) <$> Game.choose creature <*> Game.choose basicLand)
        refused = Just (Text.pack "not an answer the prompt offers")
    Spec.assertEqWith s "CR 205.3m creature type problems" (problemsOf "ChooseCreatureType" sent) [Nothing, refused]
    Spec.assertEqWith s "CR 305.6 basic land type problems" (problemsOf "ChooseBasicLandType" sent) [Nothing, refused]
    Spec.assertEqWith s "the second answers stand" chosen (Subtype.Goblin, Subtype.Swamp)

  Spec.it s "CR 509.1b an illegal block is refused naming the attacker, and asked again however often it is repeated" $ do
    drake <- S.printingOf s registry "Wind Drake"
    piker <- S.printingOf s registry "Goblin Piker"
    barbarians <- S.printingOf s registry "Balduvian Barbarians"
    -- The Piker gives the Barbarians a legal block, so bob is asked at all.
    case S.combatBoardOf [drake, piker] [barbarians] of
      (gs, [flier, walker], [blocker]) -> do
        let blocks = Protocol.encodeAnswer (Prompt.DeclareBlockers (Decider.MkDecider S.bob) S.bob [blocker] [flier, walker])
            illegal = blocks (Map.singleton blocker (Set.singleton flier))
            replies = [Protocol.encodeAnswer (Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [flier, walker]) [flier, walker], illegal, illegal, blocks Map.empty]
            (sent, after) = declaring replies gs
            refused = Just (Text.pack "the declaration of blockers is illegal: Balduvian Barbarians can't block Wind Drake")
        Spec.assertEqWith s "problems" (problemsOf "DeclareBlockers" sent) [Nothing, refused, refused]
        Spec.assertEqWith s "the drake and the Piker attack" (Map.keys (Combat.Type.attackers (GameState.combat after))) [flier, walker]
        Spec.assertEqWith s "and are unblocked" (Combat.Type.blockers (GameState.combat after)) Map.empty
      _ -> Spec.assertFailure s "fixture should have two attackers and one blocker"

  Spec.it s "CR 508.1c an illegal attack is refused, and asked again however often it is repeated" $ do
    bondedConstruct <- S.printingOf s registry "Bonded Construct"
    bears <- S.printingOf s registry "Grizzly Bears"
    -- The Bears give the Construct company in some legal declaration, so alice
    -- is asked at all.
    case S.combatBoardOf [bondedConstruct, bears] [] of
      (gs, [construct, bear], []) -> do
        let attacks = Protocol.encodeAnswer (Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [construct, bear])
            (sent, after) = declaring [attacks [construct], attacks [construct], attacks []] gs
            refused = Just (Text.pack "the declaration of attackers is illegal")
        Spec.assertEqWith s "problems" (problemsOf "DeclareAttackers" sent) [Nothing, refused, refused]
        Spec.assertEqWith s "nothing attacks" (Combat.Type.attackers (GameState.combat after)) Map.empty
      _ -> Spec.assertFailure s "fixture should have two creatures"

-- Declares attackers then blockers over the line, answering each line sent
-- with the next of `replies`; the lines sent and the state after.
declaring :: [R.Reply] -> GameState.GameState -> ([String], GameState.GameState)
declaring replies gs =
  let ((_, after), sent) = overTheLine replies gs (Combat.declareAttackers S.manaPerformer S.alice >> Combat.declareBlockers S.manaPerformer)
   in (sent, after)

-- Runs `game` over the line, answering each line sent with the next of
-- `replies`; its result and state after, and the lines sent.
overTheLine :: [R.Reply] -> GameState.GameState -> Game.Type.Game a -> ((a, GameState.GameState), [String])
overTheLine replies gs game =
  let send line = State.state $ \(out, rest) -> case rest of
        reply : more -> (Common.render (Codec.Reply.toValue reply), (out <> [Text.unpack line], more))
        [] -> error ("no reply left for " <> Text.unpack line)
      fallback :: Answerer.Answerer (Asked.Asked GameState.GameState) (State.State ([String], [R.Reply]))
      fallback = Answerer.MkAnswerer (pure . Replay.defaultAnswer . Asked.prompt)
      (ran, (sent, _)) = State.runState (Engine.runGameAsked (Answerer.unwrap (Protocol.over send fallback)) gs game) ([], replies)
   in (ran, sent)

-- The problem each line of this kind was sent with.
problemsOf :: String -> [String] -> [Maybe Text.Text]
problemsOf kind sent = [Request.problem request | Just request <- fmap requestOf sent, Question.kind (Request.question request) == Text.pack kind]

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
chance :: Answerer.Answerer (Asked.Asked GameState.GameState) (State.State Log)
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

-- Casts the first spell offered and stops paying for it, the first time; then
-- answers as `client` does.
stopsOnce :: Text.Text -> State.State Log Text.Text
stopsOnce line = do
  stopped <- State.gets (any (List.isInfixOf "\"kind\":\"ChooseManaSource\"") . Either.rights)
  case fmap Request.question (requestOf (Text.unpack line)) of
    Just question
      | Question.kind question == Text.pack "ChooseManaSource" -> pure (Text.pack "null")
      | Question.kind question == Text.pack "ChooseAction",
        not stopped,
        R.Array actions <- Question.offer question,
        Just i <- List.findIndex ((== Just (R.Text (Text.pack "Cast"))) . field "action") actions ->
          pure (Text.pack (show i))
    _ -> client line

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

arrayOf :: R.Reply -> Maybe [R.Reply]
arrayOf reply = case reply of
  R.Array xs -> Just xs
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
