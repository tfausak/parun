-- One seat's view of a game: built field by field from the state, never as a
-- redacted copy of it, so a field the state gains reaches no client until it
-- is added here on purpose.
module Pawl.Engine.PlayerView where

import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Projection.View as Projection.View
import qualified Pawl.Engine.Visibility as Visibility
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.Types.AbilityView as AbilityView
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.Mana as Mana
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.Player as Player
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.Visibility as Visibility.Type
import qualified Pawl.Types.Zone as Zone

-- | CR 400.2 / 723.4: everything `pid` may see of the game.
viewFor :: PlayerId.PlayerId -> GameState.GameState -> PlayerView.PlayerView
viewFor pid gs =
  PlayerView.MkPlayerView
    { PlayerView.viewer = pid,
      PlayerView.turn = GameState.turnNumber gs,
      PlayerView.phase = GameState.phase gs,
      PlayerView.active = GameState.activePlayer gs,
      PlayerView.priority = GameState.priority gs,
      PlayerView.seats = Maybe.mapMaybe (seatView pid gs) (GameState.turnOrder gs),
      PlayerView.battlefield = Maybe.mapMaybe (objectView pid gs) (Foldable.toList (GameState.battlefield gs)),
      PlayerView.stack = Maybe.mapMaybe (objectView pid gs) (GameState.stack gs),
      PlayerView.witnessed = witnessedIn (GameState.events gs),
      PlayerView.witnessedLastTurn = witnessedIn (GameState.eventsLastTurn gs),
      PlayerView.result = GameState.result gs
    }
  where
    witnessedIn :: Seq.Seq LoggedEvent.LoggedEvent -> [LoggedEvent.LoggedEvent]
    witnessedIn = filter (\logged -> Visibility.witnessed pid logged == Visibility.Type.Visible) . Foldable.toList

-- | CR 400.2: a hidden zone by its size and the members `pid` may see; a public
-- one in full.
--
-- Not implemented: a fresh id for a card a shuffle moves, so a seat shown a
-- library card can still tell that copy apart after the shuffle (#5223).
seatView :: PlayerId.PlayerId -> GameState.GameState -> PlayerId.PlayerId -> Maybe SeatView.SeatView
seatView pid gs seat = do
  player <- Map.lookup seat (GameState.players gs)
  let members zone = Game.zoneMembers zone seat gs
      public zone = Maybe.mapMaybe (objectView pid gs) (members zone)
      hidden zone = Maybe.mapMaybe (objectView pid gs) (filter (\oid -> Visibility.sees pid oid gs == Visibility.Type.Visible) (members zone))
  pure
    SeatView.MkSeatView
      { SeatView.player = seat,
        SeatView.life = Player.life player,
        SeatView.counters = Player.counters player,
        SeatView.handSize = Natural.length (members Zone.Hand),
        SeatView.hand = hidden Zone.Hand,
        SeatView.librarySize = Natural.length (members Zone.Library),
        SeatView.library = hidden Zone.Library,
        SeatView.graveyard = public Zone.Graveyard,
        SeatView.exile = public Zone.Exile,
        SeatView.manaPool = Map.findWithDefault (Mana.MkMana []) seat (GameState.manaPool gs)
      }

-- | CR 110.5: an object's status for anyone; its characteristics (as projected,
-- CR 613) for a seat that may see them, which for a face-down permanent or
-- spell is every seat (CR 708.2); the card behind a face-down object for a
-- seat that may look at it (CR 406.3, 708.5); and what an ability came from.
objectView :: PlayerId.PlayerId -> GameState.GameState -> ObjectId.ObjectId -> Maybe ObjectView.ObjectView
objectView pid gs oid = do
  object <- Game.lookupObject oid gs
  let seen = Visibility.sees pid oid gs == Visibility.Type.Visible
      public = Facing.isFaceDown (Object.facing object) && (Game.zoneOf oid gs == Just Zone.Battlefield || Game.zoneOf oid gs == Just Zone.Stack)
      faceDown = Facing.isFaceDown (Object.facing object) || Object.exiledFaceDown object
  pure
    ObjectView.MkObjectView
      { ObjectView.object = oid,
        ObjectView.owner = Object.owner object,
        ObjectView.controller = Projection.View.controllerOf oid gs,
        ObjectView.tapped = Object.tapped object,
        ObjectView.damage = Object.damage object,
        ObjectView.counters = Object.counters object,
        ObjectView.attachedTo = Object.attachedTo object,
        ObjectView.characteristics =
          if public || (seen && not faceDown)
            then Just (Projection.project oid gs)
            else Nothing,
        ObjectView.face =
          if seen && faceDown
            then Just (Projection.projectShown oid gs)
            else Nothing,
        ObjectView.ability = abilityView pid gs oid
      }

-- | CR 113.7a / 602.2a: an ability on the stack by its source, where `pid` may
-- know that object: one in a public zone, one `pid` sees in a hidden zone, or
-- one that has left, which the seat can name only by what it witnessed.
abilityView :: PlayerId.PlayerId -> GameState.GameState -> ObjectId.ObjectId -> Maybe AbilityView.AbilityView
abilityView pid gs oid
  | Game.isAbility oid gs = Just (AbilityView.MkAbilityView (Game.abilitySourceOf oid gs >>= known))
  | otherwise = Nothing
  where
    known source = case Game.zoneOf source gs of
      Just zone | Game.isHiddenZone zone && Visibility.sees pid source gs /= Visibility.Type.Visible -> Nothing
      _ -> Just source
