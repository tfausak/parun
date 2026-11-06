-- One GameState's shared reads, taken once and handed to every question an
-- enumeration asks of it: the whole-board projection (#200, #716), the
-- off-battlefield one, the control-grant walk, and the CR 101.2 prohibition sets a cost gate reads per
-- ability. Answers nothing a fresh read would not, the board being a snapshot
-- of one state (Parun.Engine.Projection.projectGiven).
module Parun.Engine.Snapshot where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Parun.Engine.CrewRestriction as CrewRestriction
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.SacrificeRestriction as SacrificeRestriction
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ProjectedCharacteristics (ProjectedCharacteristics)

-- LAZY FIELDS: each is a thunk until a question forces it, so a caller that
-- asks no projection question pays for no projection. Built by `given`,
-- `whole` or `onDemand` only, which keep the derived fields agreeing with the
-- first two.
data Snapshot = MkSnapshot
  { -- Every object's characteristics, or empty to project each object on
    -- demand (Projection.projectGiven's fallback).
    projected :: Map ObjectId ProjectedCharacteristics,
    -- Every object off the battlefield, each projected against one gather
    -- when first read (Projection.projectEach, #6472).
    offBoard :: Map ObjectId ProjectedCharacteristics,
    grants :: [Projection.ControlGrant],
    -- Projection.viewsOf's answer, read off `projected` for a permanent.
    views :: ObjectId -> Filter.View,
    -- CR 101.2: the permanents an effect in force says can't be sacrificed
    -- (SacrificeRestriction.cantBeSacrificed of the whole battlefield).
    unsacrificeable :: Set ObjectId,
    -- CR 702.122d: the permanents an effect in force says can't crew
    -- (CrewRestriction.cantCrew of the whole battlefield).
    cantCrewVehicles :: Set ObjectId
  }

-- The snapshot of `gs` over a board and grant list the caller already took of
-- that same `gs`.
given :: Map ObjectId ProjectedCharacteristics -> [Projection.ControlGrant] -> GameState -> Snapshot
given pcs grants_ gs =
  let fresh = Projection.viewsOf gs
      battlefield = Set.toList (GameState.battlefield gs)
   in MkSnapshot
        { projected = pcs,
          offBoard = Projection.projectEach (Set.difference (Map.keysSet (GameState.objects gs)) (GameState.battlefield gs)) gs,
          grants = grants_,
          views = \oid -> if Map.member oid pcs then Projection.viewOfObjectGiven pcs grants_ oid gs else fresh oid,
          unsacrificeable = SacrificeRestriction.cantBeSacrificed battlefield gs,
          cantCrewVehicles = CrewRestriction.cantCrew battlefield gs
        }

-- The whole board projected at once: for a caller about to ask about most of
-- the battlefield.
whole :: GameState -> Snapshot
whole gs = given (Projection.projectAll gs) (Projection.controlGrants gs) gs

-- Each object projected only when asked about: for a caller asking about one
-- object, where projecting the rest would be waste.
onDemand :: GameState -> Snapshot
onDemand gs = given Map.empty (Projection.controlGrants gs) gs
