-- | Unstable's Contraptions: assembling one from the Contraption deck onto a
-- sprocket, and the crank at the beginning of its controller's upkeep. CR
-- 701.45a leaves Unstable's mechanics out of the rules, so the ground truth is
-- the Unstable FAQ (2017-12-06) and the Gatherer rulings of 2018-01-19 on its
-- Contraptions (Arms Depot's, for one), the later of the two where they part.
--
-- Casing on sprockets is the closed half reading those rules, as
-- Pawl.Engine.SpaceSculptor reads CR 702.158's sectors: what a reader learns
-- here is which sprocket a permanent is on, never which card put it there.
module Pawl.Engine.Contraption where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Pawl.Engine.Attraction as Attraction
import qualified Pawl.Engine.Decide as Decide
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Replacement as Replacement
import qualified Pawl.Engine.Sector as Sector
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.Types.AnyNumberOf as AnyNumberOf
import qualified Pawl.Types.Designation as Designation
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameEvent as GameEvent
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.PermanentActed as PermanentActed
import qualified Pawl.Types.PermanentAction as PermanentAction
import qualified Pawl.Types.Player as Player
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.ProposedEvent as ProposedEvent
import qualified Pawl.Types.SideDeck as SideDeck
import qualified Pawl.Types.Subtype as Subtype

-- | The FAQ's assemble: this player -- or the permanent assembling for them,
-- which Steamflogger Boss's row reads -- reveals the top card of their
-- Contraption deck and puts it face up onto one of their sprockets, chosen for
-- each Contraption apart ("you choose individually for each one"). Proposed
-- first as WouldAssemble, so a row can change how many. An empty deck
-- assembles nothing and loses nobody the game.
assemble :: Maybe ObjectId -> PlayerId -> Game ()
assemble assembler pid = do
  outcome <- Event.applyReplacements (ProposedEvent.WouldAssemble assembler pid 1)
  Monad.forM_ (outcome >>= Replacement.asAssemble) $ \(_, assembling, times) ->
    Monad.replicateM_ (Natural.toIntSaturating times) (assembleOne assembling)

-- One Contraption: onto the battlefield first, then onto the sprocket its
-- controller picks, so the card is face up when the choice is put and an entry
-- a replacement kept off the battlefield asks nothing. Three sprockets are
-- always three candidates, so the prompt is never elided.
assembleOne :: PlayerId -> Game ()
assembleOne pid = do
  entered <- Attraction.enterTop SideDeck.Contraption pid
  Monad.forM_ entered $ \oid -> do
    picked <- Game.chooseAmong (\decider who -> Prompt.ChooseDesignation decider who oid) pid (NonEmpty.toList Sector.sprockets)
    Monad.forM_ picked (State.modify' . putOnSprocket oid)

-- Mark this permanent as on this sprocket, and on no other.
putOnSprocket :: ObjectId -> Designation.Designation -> GameState -> GameState
putOnSprocket oid sprocket gs =
  let move o = o {Object.designations = Set.insert sprocket (Set.filter (not . Sector.isSprocket) (Object.designations o))}
   in gs {GameState.objects = Map.adjust move oid (GameState.objects gs)}

-- | Which sprocket this player's CRANK! counter is on.
crankCounterOf :: PlayerId -> GameState -> Designation.Designation
crankCounterOf pid gs = maybe (NonEmpty.last Sector.sprockets) Player.crankCounter (Map.lookup pid (GameState.players gs))

-- | The Gatherer rulings: at the beginning of this player's upkeep, if they
-- control a Contraption, the CRANK! counter moves to their next sprocket, and
-- they may crank any number of the Contraptions on it, each cranking triggering
-- that Contraption's "whenever you crank this Contraption". The FAQ's "at the
-- start of your turn, if you have any assembled Contraptions" is the earlier
-- wording of the same action.
--
-- Cranking is always optional, so the Contraptions are offered as any number,
-- none included, and asked even of one; the answer is filtered against what was
-- offered. Their abilities are then ordered as any triggers are (CR 603.3b),
-- which is the FAQ's "in any order".
crank :: PlayerId -> Game ()
crank pid = do
  gs <- State.get
  Monad.when (Attraction.controlsSubtype Subtype.Contraption pid gs) $ do
    let next = Sector.nextSprocket (crankCounterOf pid gs)
    State.modify' (\g -> g {GameState.players = Map.adjust (\p -> p {Player.crankCounter = next}) pid (GameState.players g)})
    moved <- State.get
    let onIt oid = maybe False (Set.member next . Object.designations) (Game.lookupObject oid moved)
        candidates = filter (\oid -> onIt oid && Set.member Subtype.Contraption (Projection.subtypesOf oid moved)) (Projection.controls pid moved)
    case candidates of
      [] -> pure ()
      -- The prompt's object is the first Contraption offered: a turn-based
      -- action has no source of its own to name.
      first : _ -> do
        chosen <- Game.choose (Prompt.ChooseAnyNumber (Decide.deciderFor pid moved) pid first AnyNumberOf.ToCrank candidates Nothing)
        Monad.forM_ (filter (`Set.member` chosen) candidates) $ \oid ->
          State.modify' (Event.recordEvent (GameEvent.PermanentActed (PermanentActed.MkPermanentActed PermanentAction.Crank oid)))
