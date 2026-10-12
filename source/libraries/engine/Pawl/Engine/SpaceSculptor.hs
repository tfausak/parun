-- CR 702.158: space sculptor, the keyword that sorts creatures into CR
-- 702.158b's sectors, and the two rules that bracket a sector's life: CR
-- 704.5u's state-based action, which assigns one (`assign`), and CR 702.158b's
-- ending, "until no player controls a permanent with space sculptor or an
-- ability whose source has space sculptor" (`lapse`).
--
-- The sectors are Pawl.Types.Designation marks, so CR 400.7's new object already
-- ends one on a permanent that leaves; what this adds is the ending that the
-- SCULPTOR leaving brings to every other permanent. It is a write and not a
-- live read, Pawl.Engine.Soulbond's posture: a sector that has lapsed stays
-- lapsed when a sculptor returns, and CR 704.5u then asks again.
--
-- Casing on rule 702.158 is the closed half reading its own rulebook: what a
-- reader learns here is which sector a permanent is in, never which card put it
-- there.
module Pawl.Engine.SpaceSculptor where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Pawl.Engine.Filter as Filter
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Projection.View as Projection
import qualified Pawl.Engine.Sector as Sector
import qualified Pawl.Types.BecameDesignated as BecameDesignated
import qualified Pawl.Types.CardType as CardType
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameEvent as GameEvent
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.ProjectedCharacteristics as PC
import qualified Pawl.Types.Prompt as Prompt

-- CR 702.158b's condition for keeping a sector: some player controls a
-- permanent with space sculptor, or an ability on the stack whose source has it
-- -- read off the source's last known information once it has left (CR
-- 113.7a), so Space Beleren's -5 still finds its sectors after the Beleren is
-- gone. A phased-out sculptor is no permanent at all (CR 702.26b), which
-- GameState.battlefield already says.
sustained :: GameState -> Bool
sustained gs =
  let onBattlefield = any (\oid -> Projection.hasKeyword Keyword.SpaceSculptor oid gs) (Set.toList (GameState.battlefield gs))
      sourceSculpts oid = case Game.abilitySourceOf oid gs of
        Nothing -> False
        Just source -> maybe False (Set.member Keyword.SpaceSculptor . Filter.keywords) (Projection.viewWithLastKnownAnywhere gs source)
   in onBattlefield || any sourceSculpts (GameState.stack gs)

-- The permanents, phased out ones included: a sector lapses for those too,
-- since CR 702.158b ends it on a condition about the sculptor rather than on
-- anything that happens to the permanent.
permanents :: GameState -> [ObjectId]
permanents gs = Set.toList (GameState.battlefield gs) <> Map.keys (GameState.phasedOut gs)

inASector :: Object.Object -> Bool
inASector = any Sector.isSector . Object.designations

-- CR 702.158b: every sector ends once nothing sustains it. Asked first of the
-- STORED marks, so a board with no sector on it never projects anything.
--
-- Called from the CR 704.3 settle (`settle`) and also from Pawl.Engine.Event's
-- zone-change funnel as a permanent leaves the battlefield, because the
-- condition can fail for a moment the settle never sees: a sculptor flickered by
-- one resolution (Felidar Guardian) leaves, and nothing sustains the sectors,
-- before it comes back. Pawl.SpaceSculptorSpec's "CR 702.158b the sectors end
-- when no player controls a sculptor, even for a moment" is the proof.
lapse :: GameState -> GameState
lapse gs = if lapses gs then strip gs else gs

-- Whether `lapse` acts on this board.
lapses :: GameState -> Bool
lapses gs = any (maybe False inASector . (`Game.lookupObject` gs)) (permanents gs) && not (sustained gs)

-- Every sector off every permanent.
strip :: GameState -> GameState
strip gs =
  let unmark o = o {Object.designations = Set.filter (not . Sector.isSector) (Object.designations o)}
   in gs {GameState.objects = List.foldl' (flip (Map.adjust unmark)) (GameState.objects gs) (permanents gs)}

-- `lapse` as a CR 704.3 settle step, reporting whether it acted so the settle
-- loops: CR 704.5u then owes the creatures a sector again if a sculptor is
-- still around (one whose ability alone kept them, say, having just resolved).
settle :: Game Bool
settle = do
  gs <- State.get
  let acted = lapses gs
  Monad.when acted (State.put (strip gs))
  pure acted

-- CR 704.5u: with a permanent with space sculptor on the battlefield, each
-- creature in no sector is given one by its controller -- first every such
-- controller who controls no sculptor, then every other (CR 702.158c), each
-- group in APNAP order (CR 101.4). Every creature is its controller's own
-- prompt: three candidates, never elided.
--
-- Judged against the pre-pass board `pcs` and `gs` like every other
-- classification in Pawl.Engine.Sba.checkOnce (CR 704.3), and asked before
-- anything there moves, the legend rule's posture. Each answer is stamped as it
-- is given, so a player choosing later sees the sectors chosen before them,
-- which is what choosing in turn is for. `record` is the CR 603.2 event funnel,
-- Pawl.Engine.Event.recordEvent, passed in because that module calls `lapse`.
--
-- Reports whether anyone was asked: a creature no seat controls asks nobody, and
-- reporting it would keep CR 704.3's loop from coming to rest.
assign :: (GameEvent.GameEvent -> GameState -> GameState) -> Map.Map ObjectId PC.ProjectedCharacteristics -> GameState -> Game Bool
assign record pcs gs =
  let field = Set.toList (GameState.battlefield gs)
      sculptors = filter (\oid -> Projection.hasKeywordGiven pcs Keyword.SpaceSculptor oid gs) field
      isCreature oid = maybe False (Set.member CardType.Creature . PC.cardTypes) (Map.lookup oid pcs)
      sectorless oid = maybe False (not . inASector) (Game.lookupObject oid gs)
      waiting = if null sculptors then [] else filter (\oid -> isCreature oid && sectorless oid) field
      grants = Projection.controlGrants gs
      controllerOf oid = Projection.controllerOfGiven grants oid gs
      sculpting = Set.fromList (Maybe.mapMaybe controllerOf sculptors)
      (others, sculptorControllers) = List.partition (`Set.notMember` sculpting) (Game.apnapOrder gs)
      order = others <> sculptorControllers
      theirs pid = filter (\oid -> controllerOf oid == Just pid) waiting
      stamp oid sector g =
        record
          (GameEvent.BecameDesignated (BecameDesignated.MkBecameDesignated sector oid))
          g {GameState.objects = Map.adjust (\o -> o {Object.designations = Set.insert sector (Object.designations o)}) oid (GameState.objects g)}
   in do
        Monad.forM_ order $ \pid ->
          Monad.forM_ (theirs pid) $ \oid -> do
            picked <- Game.chooseAmong (\decider who -> Prompt.ChooseSector decider who oid) pid (NonEmpty.toList Sector.sectors)
            Monad.forM_ picked (State.modify' . stamp oid)
        pure (not (all (null . theirs) order))
