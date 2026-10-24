module Parun.Types.PlayBudget where

import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 601.3: how many more of the cards one Effect.GrantPlayFromExile covers
-- may be played under it -- March of Reckless Joy's "you may play up to two of
-- those cards". Each covered card's Parun.Types.ExilePlayPermission holds the
-- same value, and Parun.Engine.Cast.spendPlayBudget spends it across all of
-- them.
data PlayBudget = MkPlayBudget
  { -- | The plays left. Spending the last clears every permission sharing
    -- this budget.
    remaining :: Natural.Natural,
    -- | The objects the grant covered as it was granted, which is which
    -- permissions share this budget. An id that has since left exile names
    -- nothing (CR 400.7).
    covers :: Set.Set ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
