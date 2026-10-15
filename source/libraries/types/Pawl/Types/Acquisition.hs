module Pawl.Types.Acquisition where

import qualified Pawl.Types.Timestamp as Timestamp

-- | CR 607.5: which acquisition of an object's abilities an ability came with.
-- A pair of linked abilities acquired by one effect is linked only to each
-- other, so information one of them notes is keyed by this, and the other reads
-- only what was noted under its own.
--
-- Pawl.Engine.Game.acquisitionOf says which one an object's copiable abilities
-- have now, and Pawl.Types.TriggeredAbilitySource and
-- Pawl.Types.ActivatedAbilitySource freeze it as an ability goes on the stack.
data Acquisition
  = -- | CR 607.1: the abilities the object has of its own -- printed, or the
    -- copiable values it entered with (CR 707.5).
    Own
  | -- | CR 607.5: the abilities a copy effect gave it after it entered, named by
    -- that effect's timestamp (CR 613.7).
    Copied Timestamp.Timestamp
  deriving (Eq, Ord, Show)
