module Parun.Types.TapPermanents where

import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.Filter as Filter

-- | The payload of Parun.Types.CostComponent's TapPermanents arm: CR 601.2f's
-- "tapping permanents" as a cost, spent by tapping exactly this many permanents
-- the payer chooses out of the ones the Filter admits. Springleaf Drum's "Tap
-- an untapped creature you control" is the printing, and Explosive
-- Singularity's "tap any number" the announced count (CR 601.2b).
--
-- PARAMETRIC in the keyword for the Filter it carries, exactly as
-- Parun.Types.CostComponent is.
--
-- A record of its OWN rather than one shared with
-- Parun.Types.TapForTotalPower, whose fields have the same two types, for the
-- reason Parun.Types.Sacrifice gives against sharing with that same record:
-- count is HOW MANY objects and must be matched exactly, where that one's
-- totalPower is a THRESHOLD on an aggregate and determines no count at all.
--
-- Parun.Types.Sacrifice's fields, and deliberately -- this is that record's
-- question asked about tapping rather than about sacrificing, which is why the
-- field names agree. The two are still separate types because the ACTIONS
-- differ: Parun.Engine.Cost's arms pay one through Parun.Engine.Event.sacrificeAll
-- and the other with a tap, and no reader wants to be told they are the same.
data TapPermanents keyword = MkTapPermanents
  { count :: CostAmount.CostAmount,
    whichPermanents :: Filter.Filter keyword,
    -- | CR 205.3m: the permanents tapped must hold one creature type in common
    -- -- Weight of Conscience's "two untapped creatures you control that share
    -- a creature type". A joint condition on the chosen set, which no
    -- per-candidate Filter can state.
    sharingACreatureType :: Bool
  }
  deriving (Eq, Ord, Show)
