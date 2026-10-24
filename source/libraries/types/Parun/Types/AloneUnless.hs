module Parun.Types.AloneUnless where

import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 506.5 / 508.1c / 509.1b: which creatures can't attack (or block)
-- without company, what that company must be, and CR 508.1c's "unless" gate.
data AloneUnless = MkAloneUnless
  { affected :: Affected.Affected,
    -- | The other creature that must also be declared, read in the RESTRICTED
    -- creature's context, so a source-relative atom compares against it (Okk's
    -- "a creature with greater power"). Nothing is any other creature: CR
    -- 506.5's "alone" (Bonded Construct). Elided rather than written null.
    alongside :: Maybe (Filter.Filter Keyword.Keyword),
    -- | Nothing is the unconditional restriction. Elided rather than written
    -- null.
    unless :: Maybe Condition.Condition,
    -- | CR 116.2d: Parun.Types.AffectedUnless.name's field on these arms.
    name :: Maybe AbilityName.AbilityName
  }
  deriving (Eq, Ord, Show)
