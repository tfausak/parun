-- | CR 717 and CR 701.51: a player's Attraction deck and opening an Attraction
-- from it, and the move off the top of a supplementary deck that the Unstable
-- FAQ's assemble shares with it (Pawl.Engine.Contraption). Rolling to visit (CR 701.52) is a die roll and lives with the CR 706
-- pipeline in Pawl.Engine.Resolve.Effect; Pawl.Engine.Engine runs it as CR
-- 703.4g's turn-based action.
module Pawl.Engine.Attraction where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Types.EntryRiders as EntryRiders
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LibraryPosition as LibraryPosition
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.PlayerActed as PlayerActed
import qualified Pawl.Types.PlayerAction as PlayerAction
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.SideDeck as SideDeck
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.Zone as Zone

-- | CR 717.2: this player's Attraction deck, top card first.
deckOf :: PlayerId -> GameState.GameState -> [ObjectId]
deckOf = Game.sideDeckOf SideDeck.Attraction

-- | CR 717.4 and the Unstable FAQ: does this player control a permanent of this
-- subtype -- an Attraction for the roll to visit, a Contraption for the crank?
-- Read off the projection, the subtype being a characteristic.
controlsSubtype :: Subtype.Subtype -> PlayerId -> GameState.GameState -> Bool
controlsSubtype subtype pid gs = any (\oid -> Set.member subtype (Projection.subtypesOf oid gs)) (Projection.controls pid gs)

-- | CR 701.51b: move the top card of this player's Attraction deck onto the
-- battlefield under their control. GameEvent.PlayerActed is recorded only when
-- the card reached the battlefield, since an entry prevented or replaced opens
-- nothing that triggers (CR 701.51c).
open :: PlayerId -> Game ()
open pid = do
  entered <- enterTop SideDeck.Attraction pid
  Monad.unless (null entered) $
    State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.OpenAttraction pid)))

-- | CR 701.51b and the Unstable FAQ's assemble: move the top card of this
-- player's deck of this kind onto the battlefield under their control, answering
-- what reached it. Through Event.changeZoneEntering, so an entry replacement or
-- prohibition applies as to any other entry (CR 701.51c). An empty deck moves
-- nothing (CR 609.3; the FAQ for an empty Contraption deck).
enterTop :: SideDeck.SideDeck -> PlayerId -> Game [ObjectId]
enterTop kind pid = do
  gs <- State.get
  case Game.sideDeckOf kind pid gs of
    [] -> pure []
    top : _ -> do
      entered <- Event.changeZoneEntering top Zone.Battlefield LibraryPosition.defaultValue riders (Just pid)
      after <- State.get
      pure (filter (`Set.member` GameState.battlefield after) (Foldable.toList entered))

-- CR 701.51b states no riders, nor does the FAQ's assemble: the card enters
-- untapped, face up and with no counters.
riders :: EntryRiders.EntryRiders Natural ability
riders =
  EntryRiders.defaultValue
