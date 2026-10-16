module Pawl.Types.ObjectSnapshot where

import qualified Data.Set as Set
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.Zone as Zone

-- | One object as it stood at a recorded moment: its id, its projected
-- characteristics, who controlled it, who owned it and where it was. What
-- Pawl.Types.PastActivation keeps of an ability's source and targets, so a later
-- Filter is asked of the object as it WAS (CR 608.2h's posture) rather than of
-- whatever it has since become.
--
-- The id is kept, unlike a look-back event snapshot's, because the record lives
-- one turn and ids are never reused: Filter.IsSource asking "this creature" of a
-- recorded target is asking about the same incarnation (CR 400.7).
data ObjectSnapshot = MkObjectSnapshot
  { object :: ObjectId.ObjectId,
    characteristics :: ProjectedCharacteristics.ProjectedCharacteristics,
    -- | CR 108.4: Nothing for a card in a zone that gives it no controller --
    -- a cycling card in a hand.
    controller :: Maybe PlayerId.PlayerId,
    owner :: PlayerId.PlayerId,
    -- | CR 400.1: the zone it was in, which CR 109.2's "a creature" asks.
    zone :: Zone.Zone,
    -- | CR 604.2: the "as long as" clauses of its granted activated abilities
    -- that did not hold in that zone, which `characteristics` carries
    -- unasked (Pawl.Engine.Projection.View.lapsedGrantsOf).
    lapsedGrants :: Set.Set Condition.Condition
  }
  deriving (Eq, Ord, Show)
