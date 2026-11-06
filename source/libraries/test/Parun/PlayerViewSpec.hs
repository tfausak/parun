-- Pattern matching on Parun.Types.Prompt, a GADT, in an answerer below.
{-# LANGUAGE GADTs #-}

-- Covers Parun.Engine.PlayerView: what one seat's view of a game shows, and
-- that nothing it may not see reaches the encoded view.
module Parun.PlayerViewSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.BotSpec as BotSpec
import qualified Parun.Cards as Cards
import qualified Parun.Codec.PlayerView as Codec.PlayerView
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.PlayerView as PlayerView
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.Visibility as Visibility
import qualified Parun.Extra.Natural as Natural
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Play.Bot as Bot
import qualified Parun.Play.Chance as Chance
import qualified Parun.Play.Render as Render
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.AbilityView as AbilityView
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Parun.Types.Answer as Answer
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Board as Board
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Casting as Casting
import qualified Parun.Types.Choices as Choices
import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.EventGroup as EventGroup
import qualified Parun.Types.ExileLooker as ExileLooker
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Label as Label
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Looked as Looked
import qualified Parun.Types.Move as Move
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectView as ObjectView
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerControl as PlayerControl
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView.Type
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Reply as Reply
import qualified Parun.Types.RevealCause as RevealCause
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.Seat as Seat
import qualified Parun.Types.SeatView as SeatView
import qualified Parun.Types.Source as Source
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.SplitMix as SplitMix
import qualified Parun.Types.Staged as Staged
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.Visibility as Visibility.Type
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "PlayerView" $ do
  Spec.it s "an opponent's hidden cards reach no part of the encoded view" $ do
    gs <- started s registry
    let rendered = Text.unpack (Common.render (Codec.encode Codec.PlayerView.codec (PlayerView.viewFor S.bob gs)))
        hidden = hiddenOf S.alice gs
        own = Set.unions (fmap (`Projection.namesOf` gs) (Game.zoneMembers Zone.Hand S.bob gs <> Game.zoneMembers Zone.Library S.bob gs))
        theirs = Set.unions (fmap (`Projection.namesOf` gs) hidden) `Set.difference` own
        bobsHand = Set.unions (fmap (`Projection.namesOf` gs) (Game.zoneMembers Zone.Hand S.bob gs))
        named name = Text.unpack (CardName.unwrap name) `List.isInfixOf` rendered
        idOf oid = any (\key -> ("\"" <> key <> "\":" <> show (ObjectId.unwrap oid) <> ",") `List.isInfixOf` rendered) ["object", "card"]
    Spec.assertBool s (not (Set.null theirs)) "alice holds cards bob's deck lacks"
    Spec.assertBool s (not (any named (Set.toList theirs))) "no name"
    Spec.assertBool s (not (any idOf hidden)) "no id"
    Spec.assertBool s (all named (Set.toList bobsHand)) "own hand"
  Spec.it s "CR 400.2 a seat answers from its own view" $ do
    gs <- started s registry
    let prompt = Prompt.ChooseDiscard (Decide.deciderFor S.bob gs) S.bob (Game.zoneMembers Zone.Hand S.bob gs) 1
        recorder :: Answerer.Answerer (Asked.Asked PlayerView.Type.PlayerView) (State.State [PlayerView.Type.PlayerView])
        recorder = Answerer.MkAnswerer (\question -> State.put [Asked.game question] >> pure (Replay.defaultAnswer (Asked.prompt question)))
        fallback :: Answerer.Answerer (Asked.Asked GameState.GameState) (State.State [PlayerView.Type.PlayerView])
        fallback = Answerer.MkAnswerer (\asked -> State.put [] >> pure (Replay.defaultAnswer (Asked.prompt asked)))
        seen = State.execState (Answerer.unwrap (Driver.seated recorder fallback) (Asked.MkAsked [] gs prompt)) [PlayerView.viewFor S.alice gs]
    Spec.assertBool s (PlayerView.viewFor S.alice gs /= PlayerView.viewFor S.bob gs) "the two views differ"
    Spec.assertEqWith s "bob's view" seen [PlayerView.viewFor S.bob gs]
  -- Non-interference over every question of seeded bot games: each card a seat
  -- may not see becomes another card, and the seat's view does not change.
  Spec.it s "CR 400.2 nothing a seat may not see reaches its view, at any question of a bot game" $ do
    matchup <- BotSpec.bears s registry
    other <- S.printingOf s registry "Mindslaver"
    let checking = Observer.MkObserver {Observer.before = \asked -> Trans.lift (State.modify' (<> [leaks other (Asked.game asked)])), Observer.after = \_ _ -> pure ()}
        seats :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Asked.Asked GameState.GameState) (State.StateT SplitMix.SplitMix (State.State [(Int, [PlayerId.PlayerId])])))
        seats = Map.fromList [(S.alice, Driver.seated Bot.bot Chance.chance), (S.bob, Driver.seated Bot.bot Chance.chance)]
        checked seed = State.execState (State.evalStateT (Driver.match [checking] (Driver.bySeat seats Chance.chance) GameSettings.plain Map.empty matchup) (SplitMix.MkSplitMix seed)) []
        results = checked 1
    Spec.assertGtWith s "questions checked" (length results) 100
    Spec.assertEqWith s "views that moved" (concatMap snd results) []
    Spec.assertGtWith s "cards changed" (sum (fmap fst results)) 0
  Spec.it s "CR 702.106b a hidden agenda's name reaches no seat but its owner's" $ do
    action <- S.printingOf s registry "Immediate Action"
    other <- S.printingOf s registry "Mindslaver"
    let (oid, placed) = S.addObjectIn Zone.Command action S.alice (Setup.emptyGame S.bothPlayers)
        named = Map.singleton Acquisition.Own (Map.singleton S.alice (CardName.MkCardName (Text.pack "Grizzly Bears")))
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.faceDown FaceDownReason.HiddenAgenda, Object.chosenNames = named}) oid (GameState.objects placed)}
    Spec.assertEqWith s "bob's view does not move" (snd (leaks other gs)) []
    Spec.assertGtWith s "the agenda changed for bob" (fst (leaks other gs)) 0
  Spec.it s "an opponent's hand and library show only their sizes" $ do
    gs <- started s registry
    case seatOf S.alice (PlayerView.viewFor S.bob gs) of
      Nothing -> Spec.assertFailure s "no seat for alice"
      Just seat -> do
        Spec.assertEqWith s "hand size" (SeatView.handSize seat) 7
        Spec.assertEqWith s "hand" (SeatView.hand seat) []
        Spec.assertEqWith s "library size" (SeatView.librarySize seat) (Natural.length (Game.zoneMembers Zone.Library S.alice gs))
  Spec.it s "a seat's own library is hidden from it too" $ do
    gs <- started s registry
    case seatOf S.alice (PlayerView.viewFor S.alice gs) of
      Nothing -> Spec.assertFailure s "no seat for alice"
      Just seat -> do
        Spec.assertEqWith s "own library" (SeatView.library seat) []
        Spec.assertGtWith s "own library size" (SeatView.librarySize seat) 0
        Spec.assertEqWith s "own hand shown" (length (SeatView.hand seat)) 7
  Spec.it s "a spell on the stack is seen by both seats" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (_, gs) = S.addObjectIn Zone.Stack piker S.alice (Setup.emptyGame S.bothPlayers)
        topOf pid = case PlayerView.Type.stack (PlayerView.viewFor pid gs) of
          top : _ -> ObjectView.characteristics top
          [] -> Nothing
    Spec.assertBool s (Maybe.isJust (topOf S.alice)) "alice sees it"
    Spec.assertBool s (Maybe.isJust (topOf S.bob)) "bob sees it"
  -- The board puts the ability on the stack by hand rather than through a
  -- card: a regression fence on the source's visibility, not a card-driven
  -- proof.
  Spec.it s "CR 113.7a an ability names its source only to a seat that may see it" $ do
    card <- S.cardOf s registry "Mindslaver"
    ability <- maybe (Spec.assertFailure s "Mindslaver has no activated ability") pure (Maybe.listToMaybe (concatMap Face.activatedAbilities (NonEmpty.toList (Card.faces card))))
    mindslaver <- S.printingOf s registry "Mindslaver"
    let (held, g1) = S.addHandCard mindslaver S.bob (Setup.emptyGame S.bothPlayers)
        (oid, g2) = Game.freshObjectId g1
        (ts, g3) = Game.freshTimestamp g2
        source = ActivatedAbilitySource.MkActivatedAbilitySource {ActivatedAbilitySource.source = held, ActivatedAbilitySource.ability = ability, ActivatedAbilitySource.delayed = Map.empty, ActivatedAbilitySource.acquisition = Acquisition.Own}
        gs = g3 {GameState.objects = Map.insert oid (Object.newSettled S.bob (Source.OfAbility source) Zone.Stack ts) (GameState.objects g3), GameState.stack = [oid]}
        abilityFor pid = fmap ObjectView.ability (PlayerView.Type.stack (PlayerView.viewFor pid gs))
        nameFor pid = let view = PlayerView.viewFor pid gs in Render.named view oid
    Spec.assertEqWith s "alice is not told the hand card" (abilityFor S.alice) [Just (AbilityView.MkAbilityView Nothing)]
    Spec.assertEqWith s "bob is" (abilityFor S.bob) [Just (AbilityView.MkAbilityView (Just held))]
    Spec.assertEqWith s "alice's drawing" (nameFor S.alice) (Text.pack "an ability")
    Spec.assertEqWith s "bob's drawing" (nameFor S.bob) (Text.pack "Mindslaver's ability")
  Spec.it s "CR 406.3 a card exiled face down shows its owner nothing of itself" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (oid, placed) = S.addObjectIn Zone.Exile piker S.alice (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.exiledFaceDown = True}) oid (GameState.objects placed)}
        exiled pid = foldMap SeatView.exile (seatOf S.alice (PlayerView.viewFor pid gs))
    Spec.assertEqWith s "listed" (fmap ObjectView.object (exiled S.alice)) [oid]
    Spec.assertEqWith s "face down" (fmap ObjectView.characteristics (exiled S.alice)) [Nothing]
    Spec.assertEqWith s "face down to bob" (fmap ObjectView.characteristics (exiled S.bob)) [Nothing]
    Spec.assertEqWith s "no look" (fmap ObjectView.face (exiled S.alice <> exiled S.bob)) [Nothing, Nothing]
  Spec.it s "CR 406.3 a card exiled face down shows the card only to a seat that may look at it" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (oid, placed) = S.addObjectIn Zone.Exile piker S.alice (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.exiledFaceDown = True, Object.exileLookers = Set.singleton (ExileLooker.ThePlayer S.bob)}) oid (GameState.objects placed)}
        exiled pid = foldMap SeatView.exile (seatOf S.alice (PlayerView.viewFor pid gs))
    Spec.assertEqWith s "bob looks at the card" (fmap (fmap ProjectedCharacteristics.names . ObjectView.face) (exiled S.bob)) [Just (Set.singleton (S.printingName piker))]
    Spec.assertEqWith s "its owner may not" (fmap ObjectView.face (exiled S.alice)) [Nothing]
    Spec.assertEqWith s "CR 406.3a it has no characteristics to either" (fmap ObjectView.characteristics (exiled S.alice <> exiled S.bob)) [Nothing, Nothing]
  Spec.it s "CR 708.2 / 708.5 a face-down permanent shows every seat a nameless 2/2 and its controller the card" $ do
    tracker <- S.printingOf s registry "Ainok Tracker"
    let (oid, placed) = S.addPermanent tracker S.alice (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.faceDown FaceDownReason.Morphed}) oid (GameState.objects placed)}
    other <- S.printingOf s registry "Mindslaver"
    faceDownViews s tracker other gs PlayerView.Type.battlefield
  Spec.it s "CR 708.2 / 708.5 a face-down spell shows every seat a nameless 2/2 and its controller the card" $ do
    tracker <- S.printingOf s registry "Ainok Tracker"
    let (oid, placed) = S.addObjectIn Zone.Stack tracker S.alice (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.faceDown FaceDownReason.Morphed}) oid (GameState.objects placed)}
    other <- S.printingOf s registry "Mindslaver"
    faceDownViews s tracker other gs PlayerView.Type.stack
  Spec.it s "CR 406.3 a card exiled face up is seen by both seats" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (_, gs) = S.addObjectIn Zone.Exile piker S.alice (Setup.emptyGame S.bothPlayers)
        exiled pid = foldMap SeatView.exile (seatOf S.alice (PlayerView.viewFor pid gs))
    Spec.assertBool s (all (Maybe.isJust . ObjectView.characteristics) (exiled S.bob) && not (null (exiled S.bob))) "bob sees it"
  -- bob passes last, so a stale holder would read bob while alice answers.
  Spec.it s "CR 117.3b no seat holds priority while Dragon's Claw's trigger asks alice its may" $ do
    claw <- S.printingOf s registry "Dragon's Claw"
    mountain <- S.printingOf s registry "Mountain"
    goblin <- S.printingOf s registry "Raging Goblin"
    let (_, g1) = S.addPermanent claw S.alice (Setup.emptyGame S.bothPlayers)
        (_, g2) = S.addPermanent mountain S.alice g1
        (spell, g3) = S.addHandCard goblin S.alice g2
        board = g3 {GameState.activePlayer = S.alice, GameState.phase = Phase.PrecombatMain, GameState.priority = Just S.alice}
        answer :: Asked.Asked GameState.GameState r -> State.State [(PlayerId.PlayerId, Maybe PlayerId.PlayerId, [Text.Text])] r
        answer question = case Asked.prompt question of
          prompt@(Prompt.ChooseOptional _ pid _ _ _ _) -> do
            let gs = Asked.game question
            State.modify' (<> [(pid, GameState.priority gs, take 1 (Render.board (PlayerView.viewFor pid gs)))])
            pure (S.identityAnswer prompt)
          prompt -> pure (S.identityAnswer prompt)
        asked = State.execState (Engine.runGameAsked answer board (S.cast S.alice spell >> Engine.priorityLoop)) []
    Spec.assertEqWith s "alice is asked, with nobody holding priority" asked [(S.alice, Nothing, [Text.pack "Turn 1, Player 1's precombat main phase."])]
  -- Goblin Battle Jester's trigger asks alice its target in the settle, which
  -- follows the step's first grant (cast before the loop) or her cast (inside).
  Spec.it s "CR 117.5 / 117.3c no seat holds priority while Goblin Battle Jester's trigger asks its target" $ do
    jester <- S.printingOf s registry "Goblin Battle Jester"
    mountain <- S.printingOf s registry "Mountain"
    goblin <- S.printingOf s registry "Raging Goblin"
    let (_, g1) = S.addPermanent jester S.alice (Setup.emptyGame S.bothPlayers)
        (_, g2) = S.addPermanent mountain S.alice g1
        (_, g3) = S.addPermanent goblin S.bob g2
        (spell, g4) = S.addHandCard goblin S.alice g3
        board = g4 {GameState.activePlayer = S.alice, GameState.phase = Phase.PrecombatMain}
        answer :: Asked.Asked GameState.GameState r -> State.State [(PlayerId.PlayerId, Maybe PlayerId.PlayerId)] r
        answer question = case Asked.prompt question of
          prompt@(Prompt.ChooseTargets _ pid _ _) -> do
            State.modify' (<> [(pid, GameState.priority (Asked.game question))])
            pure (S.identityAnswer prompt)
          prompt -> pure (S.castAnswer prompt)
        asked script = State.execState (Engine.runGameAsked answer board script) []
    Spec.assertEqWith s "at the first grant" (asked (S.cast S.alice spell >> Engine.priorityLoop)) [(S.alice, Nothing)]
    Spec.assertEqWith s "after her cast" (asked Engine.priorityLoop) [(S.alice, Nothing)]
  Spec.it s "CR 723.4 a seat making another player's decisions sees that player's hand" $ do
    started0 <- started s registry
    let row =
          PlayerControl.MkPlayerControl
            { PlayerControl.decider = Decider.MkDecider S.alice,
              PlayerControl.duration = ControlDuration.UntilTurnEnds,
              PlayerControl.manaFromLandsOnly = False,
              PlayerControl.timestamp = Timestamp.MkTimestamp 0
            }
        gs = started0 {GameState.control = Map.singleton S.bob (row NonEmpty.:| [])}
    Spec.assertEqWith s "alice sees bob's hand" (fmap (length . SeatView.hand) (seatOf S.bob (PlayerView.viewFor S.alice gs))) (Just 7)
    Spec.assertEqWith s "without control she does not" (fmap (length . SeatView.hand) (seatOf S.bob (PlayerView.viewFor S.alice started0))) (Just 0)
  Spec.it s "a look reaches only its audience" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (oid, placed) = S.addObjectIn Zone.Hand piker S.alice (Setup.emptyGame S.bothPlayers)
        look =
          LoggedEvent.MkLoggedEvent
            { LoggedEvent.group = EventGroup.first,
              LoggedEvent.event =
                GameEvent.Looked
                  Looked.MkLooked
                    { Looked.card = oid,
                      Looked.characteristics = Projection.project oid placed,
                      Looked.audience = Set.singleton S.alice
                    }
            }
        gs = placed {GameState.events = GameState.events placed Seq.|> look}
    Spec.assertEqWith s "alice witnessed it" (length (PlayerView.Type.witnessed (PlayerView.viewFor S.alice gs))) 1
    Spec.assertEqWith s "bob did not" (length (PlayerView.Type.witnessed (PlayerView.viewFor S.bob gs))) 0
    let lastTurn = placed {GameState.eventsLastTurn = Seq.singleton look}
    Spec.assertEqWith s "bob did not, read a turn later" (length (PlayerView.Type.witnessedLastTurn (PlayerView.viewFor S.bob lastTurn))) 0
    Spec.assertEqWith s "alice witnessed it, read a turn later" (length (PlayerView.Type.witnessedLastTurn (PlayerView.viewFor S.alice lastTurn))) 1
    Spec.assertEqWith s "alice's drawing" (drawnFor S.alice gs) [Text.pack "Looked at Goblin Piker."]
  Spec.it s "CR 601.2a / 701.9a / 119.3 a spell cast, its discards, its damage and a life change are witnessed by both seats, by name" $ do
    let lands = [("s1", "Swamp"), ("s2", "Swamp"), ("s3", "Swamp"), ("m1", "Mountain"), ("m2", "Mountain"), ("p1", "Plains"), ("p2", "Plains")]
        mine =
          (S.battlefield S.alice (fmap (uncurry S.settled) lands))
            { Seat.hand = Seq.fromList [S.aliased "forest" (S.cardSetup "Forest"), S.aliased "rot" (S.cardSetup "Mind Rot"), S.aliased "hammer" (S.cardSetup "Volcanic Hammer"), S.aliased "nectar" (S.cardSetup "Sacred Nectar")]
            }
        setup = S.board (mine NonEmpty.:| [S.hand S.bob [S.cardSetup "Hill Giant", S.cardSetup "Grizzly Bears"]]) S.alice S.precombatMain
        paying refs = Choices.none {Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) refs)}
        -- CR 605.3a: a payment with sources left over ends by declining one.
        atBob refs = (paying refs) {Choices.targets = Just [S.seatRef S.bob], Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) refs <> [Nothing])}
        script =
          S.turn
            1
            [ S.on S.precombatMain S.alice (S.castAction (S.aliasRef "rot") (atBob ["s1", "s2", "s3"])),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (S.castAction (S.aliasRef "hammer") (atBob ["m1", "m2"])),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (S.castAction (S.aliasRef "nectar") (paying ["p1", "p2"])),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (S.playLand (S.aliasRef "forest"))
            ]
        sentences =
          fmap
            Text.pack
            [ "Player 1 plays Forest.",
              "Player 1 casts Mind Rot.",
              "Player 2 discards Hill Giant.",
              "Player 2 discards Grizzly Bears.",
              "Player 1 casts Volcanic Hammer.",
              "Volcanic Hammer deals 3 damage to Player 2.",
              "Player 2 loses 3 life.",
              "Player 1 casts Sacred Nectar.",
              "Player 1 gains 4 life."
            ]
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let seen = witnessedBy pid gs
          seat = Text.unpack (Render.player pid) <> ": "
      Spec.assertEqWith s (seat <> "CR 601.2a every cast, by its caster and name") [(SpellWasCast.player c, ProjectedCharacteristics.names (SpellWasCast.characteristics c)) | GameEvent.SpellCast c <- seen] (fmap (\n -> (S.alice, Set.singleton (CardName.MkCardName (Text.pack n)))) ["Mind Rot", "Volcanic Hammer", "Sacred Nectar"])
      Spec.assertEqWith s (seat <> "CR 701.9a both discards") [Discarded.player d | GameEvent.Discarded d <- seen] [S.bob, S.bob]
      Spec.assertEqWith s (seat <> "CR 404.2 both discarded cards landing face up") (Set.fromList [ProjectedCharacteristics.names (Moved.characteristics m) | GameEvent.Moved m <- seen, ZoneChange.from (Moved.change m) == Zone.Hand, ZoneChange.to (Moved.change m) == Zone.Graveyard]) (Set.fromList (fmap (Set.singleton . CardName.MkCardName . Text.pack) ["Hill Giant", "Grizzly Bears"]))
      Spec.assertEqWith s (seat <> "CR 120.3a the damage") [(DamageEvent.amount d, DamageEvent.target d) | GameEvent.DamageDealt d <- seen] [(3, Recipient.ToPlayer S.bob)]
      Spec.assertEqWith s (seat <> "CR 119.3 the life lost and gained") ([LifeChange.amount l | GameEvent.LifeLost l <- seen], [LifeChange.amount l | GameEvent.LifeGained l <- seen]) ([3], [4])
      Spec.assertEqWith s (seat <> "drawn") (List.sort (filter (`elem` sentences) (drawnFor pid gs))) (List.sort sentences)
  Spec.it s "CR 508.1 / 509.1 / 510.2 attackers, blockers, combat damage and the creatures that died are witnessed by both seats, by name" $ do
    let setup = S.duel S.declareAttackers [S.settled "bear" "Grizzly Bears", S.settled "giant" "Hill Giant"] [S.settled "lizard" "Lizard Warrior"]
        script =
          S.turn
            1
            [ S.on S.declareAttackers S.alice (S.attack [S.aliasRef "bear", S.aliasRef "giant"]),
              S.on S.declareBlockers S.bob (S.block [(S.aliasRef "lizard", S.aliasRef "bear")])
            ]
        sentences =
          fmap
            Text.pack
            [ "Grizzly Bears attacks Player 2.",
              "Hill Giant attacks Player 2.",
              "Lizard Warrior blocks Grizzly Bears.",
              "Grizzly Bears deals 2 damage to Lizard Warrior.",
              "Lizard Warrior deals 4 damage to Grizzly Bears.",
              "Hill Giant deals 3 damage to Player 2.",
              "Player 2 loses 3 life.",
              "Grizzly Bears is put into a graveyard from the battlefield.",
              "Lizard Warrior is put into a graveyard from the battlefield."
            ]
    gs <- S.play s registry setup script S.combatGame
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let seen = witnessedBy pid gs
          seat = Text.unpack (Render.player pid) <> ": "
          died = [ProjectedCharacteristics.names (Moved.characteristics m) | GameEvent.Moved m <- seen, ZoneChange.from (Moved.change m) == Zone.Battlefield, ZoneChange.to (Moved.change m) == Zone.Graveyard]
      Spec.assertEqWith s (seat <> "CR 508.1 both attackers, at bob") [AttackerDeclared.target a | GameEvent.AttackerDeclared a <- seen] [AttackTarget.OfPlayer S.bob, AttackTarget.OfPlayer S.bob]
      Spec.assertEqWith s (seat <> "CR 509.1 the block") (length [() | GameEvent.BecameBlocking _ <- seen]) 1
      Spec.assertEqWith s (seat <> "CR 510.2 the damage") (List.sort [DamageEvent.amount d | GameEvent.DamageDealt d <- seen]) [2, 3, 4]
      Spec.assertEqWith s (seat <> "CR 704.5g both creatures that died") (Set.fromList died) (Set.fromList (fmap (Set.singleton . CardName.MkCardName . Text.pack) ["Grizzly Bears", "Lizard Warrior"]))
      Spec.assertEqWith s (seat <> "drawn") (List.sort (filter (`elem` sentences) (drawnFor pid gs))) (List.sort sentences)
  Spec.it s "CR 603.10a a permanent put from the battlefield into a library is witnessed by both seats, by name" $ do
    let mine =
          (S.battlefield S.alice (fmap (uncurry S.settled) [("i1", "Island"), ("i2", "Island"), ("i3", "Island")]))
            { Seat.hand = Seq.singleton (S.aliased "ebb" (S.cardSetup "Time Ebb"))
            }
        setup = S.board (mine NonEmpty.:| [S.battlefield S.bob [S.settled "giant" "Hill Giant"]]) S.alice S.precombatMain
        choices = Choices.none {Choices.targets = Just [S.aliasRef "giant"], Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) ["i1", "i2", "i3"])}
        script = S.turn 1 [S.on S.precombatMain S.alice (S.castAction (S.aliasRef "ebb") choices)]
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let seat = Text.unpack (Render.player pid) <> ": "
      Spec.assertEqWith s (seat <> "CR 603.10a the giant, seen leaving") [ProjectedCharacteristics.names (Moved.characteristics m) | GameEvent.Moved m <- witnessedBy pid gs, ZoneChange.to (Moved.change m) == Zone.Library] [Set.singleton (CardName.MkCardName (Text.pack "Hill Giant"))]
      Spec.assertBool s (Text.pack "Hill Giant moves from the battlefield to a library." `elem` drawnFor pid gs) (seat <> "drawn")
  Spec.it s "CR 400.2 / 701.23a a land searched out onto the battlefield is witnessed by both seats as it arrives, the rest of the library by neither" $ do
    let mine =
          (S.battlefield S.alice (fmap (uncurry S.settled) [("f1", "Forest"), ("f2", "Forest"), ("f3", "Forest")]))
            { Seat.hand = Seq.singleton (S.aliased "wilds" (S.cardSetup "Untamed Wilds")),
              Seat.library = Seq.fromList [S.aliased "hill" (S.cardSetup "Hill Giant"), S.aliased "found" (S.cardSetup "Plains")]
            }
        setup = S.board (mine NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) ["f1", "f2", "f3"])}
        answering prompt label = Move.Answer (Answer.MkAnswer (Text.pack prompt) (Reply.Array [Reply.Text (Text.pack label)]) False)
        script =
          S.turn
            1
            [ S.on S.precombatMain S.alice (S.castAction (S.aliasRef "wilds") choices),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (answering "Search" "$found"),
              S.on S.precombatMain S.alice (answering "Shuffle" "$hill")
            ]
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let seat = Text.unpack (Render.player pid) <> ": "
      Spec.assertEqWith s (seat <> "CR 400.2 the land, seen arriving") [ProjectedCharacteristics.names (Moved.characteristics m) | GameEvent.Moved m <- witnessedBy pid gs, ZoneChange.from (Moved.change m) == Zone.Library] [Set.singleton (CardName.MkCardName (Text.pack "Plains"))]
      Spec.assertBool s (Text.pack "Plains moves from a library to the battlefield." `elem` drawnFor pid gs) (seat <> "drawn")
    Spec.assertBool s (not ("Hill Giant" `List.isInfixOf` encodedFor S.bob gs)) "CR 701.23a the card alice saw searching reaches no part of bob's view"
  -- Beacon of Destruction's shuffle keeps the Giant on top, where alice sees it
  -- before and after through Vizier of the Menagerie, a look no event logs; the
  -- Bears reached no seat.
  Spec.it s "CR 701.24a a library card whose id reached a seat comes out of the shuffle a new object" $ do
    let mountains = fmap (\n -> "m" <> show n) [1 :: Int .. 5]
        mine =
          (S.battlefield S.alice (S.settled "vizier" "Vizier of the Menagerie" : fmap (`S.settled` "Mountain") mountains))
            { Seat.hand = Seq.singleton (S.aliased "beacon" (S.cardSetup "Beacon of Destruction")),
              Seat.library = Seq.fromList [S.aliased "giant" (S.cardSetup "Hill Giant"), S.aliased "bears" (S.cardSetup "Grizzly Bears")]
            }
        setup = S.board (mine NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.targets = Just [S.seatRef S.bob], Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) mountains)}
        answering prompt labels = Move.Answer (Answer.MkAnswer (Text.pack prompt) (Reply.Array (fmap (Reply.Text . Text.pack) labels)) False)
        script =
          S.turn
            1
            [ S.on S.precombatMain S.alice (S.castAction (S.aliasRef "beacon") choices),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (answering "Shuffle" ["$giant", "$bears", "Beacon of Destruction"])
            ]
        seenLibrary gs = [(ObjectView.object o, fmap ProjectedCharacteristics.names (ObjectView.characteristics o)) | seat <- Maybe.maybeToList (seatOf S.alice (PlayerView.viewFor S.alice gs)), o <- SeatView.library seat]
        giantName = Just (Set.singleton (CardName.MkCardName (Text.pack "Hill Giant")))
    built <- S.buildBoardOrFail s registry setup
    let labelled name = maybe (Spec.assertFailure s ("no " <> name)) pure (Map.lookup (Label.MkLabel (Text.pack name)) (Staged.objects built))
    giant <- labelled "giant"
    bears <- labelled "bears"
    after <- S.play s registry setup script S.priorityGame
    Spec.assertEqWith s "CR 701.24a alice sees a Hill Giant atop her library after the shuffle, under a new id" (fmap (\(oid, names) -> (oid == giant, names)) (seenLibrary after)) [(False, giantName)]
    Spec.assertEqWith s "the Bears no seat saw keeps its id" (Game.zoneOf bears after) (Just Zone.Library)
    Spec.assertEqWith s "before the shuffle alice saw the Giant under its id" (seenLibrary (Staged.state built)) [(giant, giantName)]
    Spec.assertEqWith s "Beacon of Destruction shuffled itself in" (length (Game.zoneMembers Zone.Library S.alice after)) 3
  -- A reveal on alice's turn, then bob's turn begins and alice's library is
  -- shuffled: bob's view still names the Giant by last turn's reveal.
  Spec.it s "CR 701.24a a library card revealed on an earlier turn comes out of the shuffle a new object" $ do
    giantCard <- S.printingOf s registry "Hill Giant"
    bearsCard <- S.printingOf s registry "Grizzly Bears"
    let (bears, g0) = S.addLibraryCard bearsCard S.alice (Setup.emptyGame S.bothPlayers)
        (giant, g1) = S.addLibraryCard giantCard S.alice g0
        (_, revealed) = Engine.runGamePure S.castAnswer g1 (Event.reveal RevealCause.Ordinary S.alice giant)
        (_, after) = Engine.runGamePure S.castAnswer (Engine.beginTurnOf S.bob revealed) (Event.shuffleLibrary S.alice)
        heldByBob = [Revealed.card r | GameEvent.Revealed r <- fmap LoggedEvent.event (PlayerView.Type.witnessedLastTurn (PlayerView.viewFor S.bob after))]
    Spec.assertEqWith s "CR 701.24a no card in alice's library carries the id bob holds from last turn's reveal" (filter (`elem` Game.zoneMembers Zone.Library S.alice after) heldByBob) []
    Spec.assertEqWith s "bob holds the Giant's id from last turn's reveal" heldByBob [giant]
    Spec.assertEqWith s "the Bears no seat saw keeps its id" (Game.zoneOf bears after) (Just Zone.Library)
  Spec.it s "CR 700.3 Curator of Destinies's face-up pile is seen moving to the hand, and its face-down pile is not" $ do
    let islands = fmap (\n -> "i" <> show n) [1 :: Int .. 6]
        mine =
          (S.battlefield S.alice (fmap (`S.settled` "Island") islands))
            { Seat.hand = Seq.singleton (S.aliased "curator" (S.cardSetup "Curator of Destinies")),
              Seat.library = Seq.fromList [S.aliased "piker" (S.cardSetup "Goblin Piker"), S.aliased "giant" (S.cardSetup "Hill Giant")]
            }
        setup = S.board (mine NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) islands)}
        answering prompt label = Move.Answer (Answer.MkAnswer (Text.pack prompt) (Reply.Array [Reply.Text (Text.pack label)]) False)
        taking label =
          S.turn
            1
            [ S.on S.precombatMain S.alice (S.castAction (S.aliasRef "curator") choices),
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice Move.Pass,
              S.on S.precombatMain S.alice (answering "ChooseAnyNumberIntoPile" "$piker"),
              S.on S.precombatMain S.bob (answering "ChoosePile" label)
            ]
        nameOf card = Set.singleton (CardName.MkCardName (Text.pack card))
        movedTo zone gs = [ProjectedCharacteristics.names (Moved.characteristics m) | GameEvent.Moved m <- witnessedBy S.bob gs, ZoneChange.from (Moved.change m) == Zone.Library, ZoneChange.to (Moved.change m) == zone]
    faceUpTaken <- S.play s registry setup (taking "$piker") S.priorityGame
    Spec.assertEqWith s "bob saw the face-up pile reach alice's hand" (movedTo Zone.Hand faceUpTaken) [nameOf "Goblin Piker"]
    Spec.assertEqWith s "and the face-down one land in her graveyard" (movedTo Zone.Graveyard faceUpTaken) [nameOf "Hill Giant"]
    faceDownTaken <- S.play s registry setup (taking "$giant") S.priorityGame
    Spec.assertEqWith s "bob did not see the face-down pile reach alice's hand" (movedTo Zone.Hand faceDownTaken) []
    Spec.assertEqWith s "bob saw the face-up pile land in her graveyard" (movedTo Zone.Graveyard faceDownTaken) [nameOf "Goblin Piker"]
    Spec.assertBool s (not ("Hill Giant" `List.isInfixOf` encodedFor S.bob faceDownTaken)) "the face-down card reaches no part of bob's view"
  Spec.it s "CR 305.1 / 701.8a a land played this turn and then destroyed is drawn leaving the battlefield like every other" $ do
    let lands = [("p1", "Plains"), ("p2", "Plains"), ("p3", "Plains"), ("p4", "Plains")]
        mine =
          (S.battlefield S.alice (fmap (uncurry S.settled) lands))
            { Seat.hand = Seq.fromList [S.aliased "played" (S.cardSetup "Plains"), S.aliased "geddon" (S.cardSetup "Armageddon")]
            }
        setup = S.board (mine NonEmpty.:| [S.battlefield S.bob [S.settled "theirs" "Forest"]]) S.alice S.precombatMain
        -- CR 605.3a: the played Plains is left over, so the payment declines it.
        choices = Choices.none {Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef . fst) lands <> [Nothing])}
        script =
          S.turn
            1
            [ S.on S.precombatMain S.alice (S.playLand (S.aliasRef "played")),
              S.on S.precombatMain S.alice (S.castAction (S.aliasRef "geddon") choices)
            ]
        died name = Text.pack (name <> " is put into a graveyard from the battlefield.")
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let drawn = drawnFor pid gs
          seat = Text.unpack (Render.player pid) <> ": "
      Spec.assertEqWith s (seat <> "every Plains, the one played this turn too") (length (filter (== died "Plains") drawn)) 5
      Spec.assertEqWith s (seat <> "bob's Forest") (length (filter (== died "Forest") drawn)) 1
      Spec.assertEqWith s (seat <> "the land play, once") (filter (Text.isInfixOf (Text.pack "Plains moves")) drawn <> filter (== Text.pack "Player 1 plays Plains.") drawn) [Text.pack "Player 1 plays Plains."]
      Spec.assertBool s (Text.pack "Armageddon is put into a graveyard from the stack." `elem` drawn) (seat <> "CR 608.2n the spell's own move, told by no other entry")
      Spec.assertEqWith s (seat <> "CR 601.2a the cast's move, told by the cast") (filter (Text.isInfixOf (Text.pack "to the stack")) drawn) []
  Spec.it s "CR 121.1 / 401.2 a draw is witnessed by both seats as the act alone, never the card" $ do
    let mine = (S.playerSetup S.alice) {Seat.library = Seq.fromList [S.cardSetup "Lava Axe", S.cardSetup "Forest"]}
        theirs = (S.playerSetup S.bob) {Seat.library = Seq.fromList [S.cardSetup "Forest"]}
        -- CR 103.8a: turn 2, since the first turn's draw is skipped.
        setup = (S.board (mine NonEmpty.:| [theirs]) S.alice (Phase.Beginning BeginningStep.DrawStep)) {Board.turn = 2}
    gs <- S.play s registry setup Seq.empty S.drawStep
    Spec.assertBool s (not ("Lava Axe" `List.isInfixOf` encodedFor S.bob gs)) "CR 401.2 bob's view names no card alice drew"
    Spec.assertBool s ("Lava Axe" `List.isInfixOf` encodedFor S.alice gs) "the control: alice's own view names it, in her hand"
    Monad.forM_ [S.alice, S.bob] $ \pid -> do
      let seen = witnessedBy pid gs
          seat = Text.unpack (Render.player pid) <> ": "
      Spec.assertEqWith s (seat <> "CR 121.1 alice drew") [Drew.player d | GameEvent.Drew d <- seen] [S.alice]
      Spec.assertEqWith s (seat <> "CR 401.2 the move from library to hand is no one's to witness") (length [() | GameEvent.Moved _ <- seen]) 0
      Spec.assertBool s (Text.pack "Player 1 draws a card." `elem` drawnFor pid gs) (seat <> "drawn")
  Spec.it s "CR 708.4 a spell cast face down is witnessed by both seats as a face-down spell" $ do
    let mine =
          (S.battlefield S.alice (fmap (uncurry S.settled) [("m1", "Mountain"), ("m2", "Mountain"), ("m3", "Mountain")]))
            { Seat.hand = Seq.singleton (S.aliased "tracker" (S.cardSetup "Ainok Tracker"))
            }
        setup = S.board (mine NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.manaSources = Seq.fromList (fmap (Just . S.aliasRef) ["m1", "m2", "m3"])}
        script = S.turn 1 [S.on S.precombatMain S.alice (Move.Cast (Casting.MkCasting (S.aliasRef "tracker") choices (Just True) Nothing))]
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid ->
      Spec.assertEqWith s (Text.unpack (Render.player pid) <> ": CR 708.2a a nameless cast") [ProjectedCharacteristics.names (SpellWasCast.characteristics c) | GameEvent.SpellCast c <- witnessedBy pid gs] [Set.empty]
    Spec.assertBool s (not ("Ainok Tracker" `List.isInfixOf` encodedFor S.bob gs)) "CR 708.5 no name in bob's encoded view"
    Spec.assertBool s (Text.pack "Player 1 casts a face-down card." `elem` drawnFor S.bob gs) "drawn"

-- Alice's face-down Ainok Tracker, read off the zone `zoneOf` lists from both
-- seats: the CR 708.2a values to each, the card to alice alone, no name of it
-- in bob's encoded view or drawing, and nothing in bob's view as it becomes
-- `other`.
faceDownViews :: (Monad m) => Spec.Spec m n -> Printing.Printing -> Printing.Printing -> GameState.GameState -> (PlayerView.Type.PlayerView -> [ObjectView.ObjectView]) -> m ()
faceDownViews s tracker other gs zoneOf = do
  let viewOf pid = zoneOf (PlayerView.viewFor pid gs)
      shown pid = fmap (\c -> (ProjectedCharacteristics.names c, ProjectedCharacteristics.power c, ProjectedCharacteristics.toughness c)) . ObjectView.characteristics <$> viewOf pid
      card pid = fmap (\c -> (ProjectedCharacteristics.names c, ProjectedCharacteristics.power c)) . ObjectView.face <$> viewOf pid
      nameless :: Maybe (Set.Set CardName.CardName, Maybe Integer, Maybe Integer)
      nameless = Just (Set.empty, Just 2, Just 2)
      name = S.printingName tracker
      rendered = Text.unpack (Common.render (Codec.encode Codec.PlayerView.codec (PlayerView.viewFor S.bob gs)))
  Spec.assertEqWith s "CR 708.2 bob sees a nameless 2/2" (shown S.bob) [nameless]
  Spec.assertEqWith s "CR 708.5 alice looks at the card" (card S.alice) [Just (Set.singleton name, Just 3)]
  Spec.assertEqWith s "CR 708.5 bob may not" (card S.bob) [Nothing]
  Spec.assertEqWith s "CR 708.2 alice's permanent is the 2/2 all the same" (shown S.alice) [nameless]
  Spec.assertBool s (not (Text.unpack (CardName.unwrap name) `List.isInfixOf` rendered)) "no name in bob's encoded view"
  Spec.assertEqWith s "bob's drawing" (fmap (Render.describe (PlayerView.viewFor S.bob gs)) (viewOf S.bob)) [Text.pack "a face-down card 2/2"]
  Spec.assertEqWith s "alice's drawing" (fmap (Render.describe (PlayerView.viewFor S.alice gs)) (viewOf S.alice)) [Text.pack "a face-down card (Ainok Tracker) 2/2"]
  Spec.assertEqWith s "CR 708.5 bob's view does not move as the card behind it changes" (snd (leaks other gs)) []

-- Each seat whose view moves when every object it may not see (CR 400.2) is
-- given `other`'s card and other chosen names, with how many objects changed
-- across the seats.
leaks :: Printing.Printing -> GameState.GameState -> (Int, [PlayerId.PlayerId])
leaks other gs =
  let changed pid = length (filter (hiddenFrom pid) (Map.keys (GameState.objects gs)))
      hiddenFrom pid oid = Visibility.sees pid oid gs /= Visibility.Type.Visible
      moved pid = PlayerView.viewFor pid (perturbed other pid gs) /= PlayerView.viewFor pid gs
      seats = NonEmpty.toList S.bothPlayers
   in (sum (fmap changed seats), filter moved seats)

-- Every object `pid` may not see, its card `other` and its chosen names
-- another.
perturbed :: Printing.Printing -> PlayerId.PlayerId -> GameState.GameState -> GameState.GameState
perturbed other pid gs =
  let (printingId, interned) = Game.intern other gs
      renamed = CardName.MkCardName (Text.pack "Mindslaver")
      swap oid obj
        | Visibility.sees pid oid gs == Visibility.Type.Visible = obj
        | otherwise =
            obj
              { Object.source = case Object.source obj of
                  Source.OfCard _ -> Source.OfCard printingId
                  source -> source,
                Object.chosenNames = fmap (fmap (const renamed)) (Object.chosenNames obj)
              }
   in interned {GameState.objects = Map.mapWithKey swap (GameState.objects interned)}

-- A game after setup: alice red, bob green, hands drawn.
started :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m GameState.GameState
started s registry = do
  red <- Cards.redDeck (S.printingOf s registry)
  green <- Cards.greenDeck (S.printingOf s registry)
  let matchup = (S.alice, red) NonEmpty.:| [(S.bob, green)]
  pure (snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)))

-- A player's hand and library.
hiddenOf :: PlayerId.PlayerId -> GameState.GameState -> [ObjectId.ObjectId]
hiddenOf pid gs = Game.zoneMembers Zone.Hand pid gs <> Game.zoneMembers Zone.Library pid gs

-- The events a seat's view says it witnessed this turn.
witnessedBy :: PlayerId.PlayerId -> GameState.GameState -> [GameEvent.GameEvent]
witnessedBy pid = fmap LoggedEvent.event . PlayerView.Type.witnessed . PlayerView.viewFor pid

-- The text client's sentence for each of them.
drawnFor :: PlayerId.PlayerId -> GameState.GameState -> [Text.Text]
drawnFor pid gs =
  let view = PlayerView.viewFor pid gs
   in Maybe.mapMaybe (Render.event view) (PlayerView.Type.witnessed view)

-- A seat's view as its client receives it.
encodedFor :: PlayerId.PlayerId -> GameState.GameState -> String
encodedFor pid gs = Text.unpack (Common.render (Codec.encode Codec.PlayerView.codec (PlayerView.viewFor pid gs)))

seatOf :: PlayerId.PlayerId -> PlayerView.Type.PlayerView -> Maybe SeatView.SeatView
seatOf pid = List.find ((== pid) . SeatView.player) . PlayerView.Type.seats
