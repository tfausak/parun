-- Covers Pawl.Engine.PlayerView: what one seat's view of a game shows, and
-- that nothing it may not see reaches the encoded view.
module Pawl.PlayerViewSpec where

import qualified Control.Monad as Monad
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Cards as Cards
import qualified Pawl.Codec.PlayerView as Codec.PlayerView
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.PlayerView as PlayerView
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Play.Render as Render
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.AbilityView as AbilityView
import qualified Pawl.Types.Acquisition as Acquisition
import qualified Pawl.Types.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Pawl.Types.Answer as Answer
import qualified Pawl.Types.AttackTarget as AttackTarget
import qualified Pawl.Types.AttackerDeclared as AttackerDeclared
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.Board as Board
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Casting as Casting
import qualified Pawl.Types.Choices as Choices
import qualified Pawl.Types.ControlDuration as ControlDuration
import qualified Pawl.Types.DamageEvent as DamageEvent
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Discarded as Discarded
import qualified Pawl.Types.Drew as Drew
import qualified Pawl.Types.EventGroup as EventGroup
import qualified Pawl.Types.ExileLooker as ExileLooker
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.FaceDownReason as FaceDownReason
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LifeChange as LifeChange
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.Looked as Looked
import qualified Pawl.Types.Move as Move
import qualified Pawl.Types.Moved as Moved
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerControl as PlayerControl
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView.Type
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.Reply as Reply
import qualified Pawl.Types.Seat as Seat
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.Source as Source
import qualified Pawl.Types.SpellWasCast as SpellWasCast
import qualified Pawl.Types.Timestamp as Timestamp
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneChange as ZoneChange

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
    faceDownViews s tracker gs PlayerView.Type.battlefield
  Spec.it s "CR 708.2 / 708.5 a face-down spell shows every seat a nameless 2/2 and its controller the card" $ do
    tracker <- S.printingOf s registry "Ainok Tracker"
    let (oid, placed) = S.addObjectIn Zone.Stack tracker S.alice (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.faceDown FaceDownReason.Morphed}) oid (GameState.objects placed)}
    faceDownViews s tracker gs PlayerView.Type.stack
  Spec.it s "CR 406.3 a card exiled face up is seen by both seats" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (_, gs) = S.addObjectIn Zone.Exile piker S.alice (Setup.emptyGame S.bothPlayers)
        exiled pid = foldMap SeatView.exile (seatOf S.alice (PlayerView.viewFor pid gs))
    Spec.assertBool s (all (Maybe.isJust . ObjectView.characteristics) (exiled S.bob) && not (null (exiled S.bob))) "bob sees it"
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
        script = S.turn 1 [S.on S.precombatMain S.alice (Move.Cast (Casting.MkCasting (S.aliasRef "tracker") choices (Just True)))]
    gs <- S.play s registry setup script S.priorityGame
    Monad.forM_ [S.alice, S.bob] $ \pid ->
      Spec.assertEqWith s (Text.unpack (Render.player pid) <> ": CR 708.2a a nameless cast") [ProjectedCharacteristics.names (SpellWasCast.characteristics c) | GameEvent.SpellCast c <- witnessedBy pid gs] [Set.empty]
    Spec.assertBool s (not ("Ainok Tracker" `List.isInfixOf` encodedFor S.bob gs)) "CR 708.5 no name in bob's encoded view"
    Spec.assertBool s (Text.pack "Player 1 casts a face-down card." `elem` drawnFor S.bob gs) "drawn"

-- Alice's face-down Ainok Tracker, read off the zone `zoneOf` lists from both
-- seats: the CR 708.2a values to each, the card to alice alone, and no name of
-- it in bob's encoded view or drawing.
faceDownViews :: (Monad m) => Spec.Spec m n -> Printing.Printing -> GameState.GameState -> (PlayerView.Type.PlayerView -> [ObjectView.ObjectView]) -> m ()
faceDownViews s tracker gs zoneOf = do
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
