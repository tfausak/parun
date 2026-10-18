-- Covers Pawl.Engine.PlayerView: what one seat's view of a game shows, and
-- that nothing it may not see reaches the encoded view.
module Pawl.PlayerViewSpec where

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
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.ControlDuration as ControlDuration
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.EventGroup as EventGroup
import qualified Pawl.Types.ExileLooker as ExileLooker
import qualified Pawl.Types.FaceDownReason as FaceDownReason
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.Looked as Looked
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.PlayerControl as PlayerControl
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView.Type
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.Timestamp as Timestamp
import qualified Pawl.Types.Zone as Zone

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
  Spec.assertEqWith s "bob's drawing" (fmap Render.describe (viewOf S.bob)) [Text.pack "a face-down card 2/2"]
  Spec.assertEqWith s "alice's drawing" (fmap Render.describe (viewOf S.alice)) [Text.pack "a face-down card (Ainok Tracker) 2/2"]

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

seatOf :: PlayerId.PlayerId -> PlayerView.Type.PlayerView -> Maybe SeatView.SeatView
seatOf pid = List.find ((== pid) . SeatView.player) . PlayerView.Type.seats
