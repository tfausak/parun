-- | What one player may see of one object (CR 400.2). The one place that asks;
-- each later source of visibility joins as a term of sees.
module Pawl.Engine.Visibility where

import qualified Data.Map as Map
import qualified Pawl.Engine.Decide as Decide
import qualified Pawl.Engine.Exile as Exile
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection.View as View
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.Phase as Phase
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.RevealWindow as RevealWindow
import qualified Pawl.Types.Visibility as Visibility
import qualified Pawl.Types.Zone as Zone

-- | Whether a player may see an object's face now. CR 723.4: for an object in
-- the game, a player also sees what each player they control sees; a card
-- outside the game (CR 400.11) is seen by its owner alone, never through
-- control.
sees :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
sees pid oid gs =
  revealedNow oid gs <> case Game.zoneOf oid gs of
    Nothing -> base pid oid gs
    Just _ -> foldMap (\seat -> base seat oid gs) (pid : controlledBy pid gs)

-- | CR 701.20a: a card in a lasting reveal is seen by every player while its
-- window is live.
revealedNow :: ObjectId -> GameState.GameState -> Visibility.Visibility
revealedNow oid gs =
  let begun logged = case LoggedEvent.event logged of
        GameEvent.StepBegan _ -> True
        _ -> False
      live window = case window of
        RevealWindow.WhileOnStack sid -> Game.zoneOf sid gs == Just Zone.Stack -- CR 701.20a
        RevealWindow.UntilFirstTurn -> GameState.turnNumber gs == 1 && not (any begun (GameState.events gs)) -- CR 103.6b
        RevealWindow.DuringUpkeep turn -> GameState.turnNumber gs == turn && GameState.phase gs == Phase.Beginning BeginningStep.Upkeep -- CR 702.57b
   in case Game.lookupObject oid gs >>= Object.revealed of
        Nothing -> Visibility.Obscured
        Just window -> visibleIf (live window)

-- | CR 723.5: the players whose decisions this player makes, by the reading
-- Pawl.Engine.Decide.deciderFor makes, so a dormant row waiting for its spell
-- (CR 723.2) or one overwritten by a later control (CR 723.1a) lends no sight.
controlledBy :: PlayerId -> GameState.GameState -> [PlayerId]
controlledBy pid gs =
  [ seat
  | seat <- Map.keys (GameState.control gs),
    seat /= pid,
    Decider.unwrap (Decide.deciderFor seat gs) == pid
  ]

-- One player's own sight, before CR 723.4.
--
-- Not implemented: a card in an Attraction, planar or scheme deck is face down
-- (CR 314.6, 701.31b, 701.51b, 729.5a) but answers here as its facing does
-- (#4990).
base :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
base pid oid gs = case Game.lookupObject oid gs of
  Nothing -> Visibility.Obscured
  Just obj -> case Game.zoneOf oid gs of
    Nothing -> visibleIf (Object.owner obj == pid) -- CR 400.11
    Just Zone.Library -> Visibility.Obscured -- CR 401.2
    Just Zone.Hand ->
      if Game.keptFaceDown oid gs
        then Visibility.Obscured -- CR 121.8, 708.5
        else visibleIf (Object.owner obj == pid) -- CR 400.2
    Just Zone.Exile -> visibleIf (Exile.mayLookAt pid oid gs) -- CR 406.3
    Just zone -> case Object.facing obj of
      Facing.FaceUp -> Visibility.Visible
      Facing.FaceDown _ ->
        if zone == Zone.Battlefield || zone == Zone.Stack
          then visibleIf (View.controllerOf oid gs == Just pid) -- CR 708.5
          else Visibility.Obscured -- CR 708.5

visibleIf :: Bool -> Visibility.Visibility
visibleIf seen = if seen then Visibility.Visible else Visibility.Obscured
