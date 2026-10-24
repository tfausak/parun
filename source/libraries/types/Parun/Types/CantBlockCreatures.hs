module Parun.Types.CantBlockCreatures where

import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 509.1b's pairwise restriction written from the BLOCKER's side: which
-- blockers are restricted, which attackers they may not block, and CR 508.1c's
-- "unless" gate. Parun.Types.CantBeBlockedBy's mirror.
data CantBlockCreatures = MkCantBlockCreatures
  { affected :: Affected.Affected,
    -- | Read in the BLOCKER's context, so a source-relative atom compares
    -- against the blocker (Spitfire Handler).
    attackers :: Filter.Filter Keyword.Keyword,
    -- | Nothing is the unconditional restriction. Elided rather than written
    -- null.
    unless :: Maybe Condition.Condition,
    -- | CR 116.2d: Parun.Types.CantBeBlockedBy.name's field on this arm.
    name :: Maybe AbilityName.AbilityName
  }
  deriving (Eq, Ord, Show)
