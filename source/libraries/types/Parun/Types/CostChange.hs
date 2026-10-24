module Parun.Types.CostChange where

import qualified Parun.Types.AppliedReduction as AppliedReduction
import qualified Parun.Types.CostAddition as CostAddition
import qualified Parun.Types.ManaCost as ManaCost

-- | CR 601.2f: what a Parun.Types.CostModifier does to the total cost.
data CostChange
  = -- | CR 601.2f's "cost increases", these mana symbols (Thalia's {1},
    -- Derelor's {B}).
    Increase ManaCost.ManaCost
  | -- | CR 601.2f / 118.7's "cost reductions" (Sapphire Medallion, Heartstone).
    Reduce AppliedReduction.AppliedReduction
  | -- | CR 601.2f / 118.8's additional costs applied from another effect
    -- (Drought, Brutal Suppression).
    Add CostAddition.CostAddition
  deriving (Eq, Ord, Show)
