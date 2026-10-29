module Parun.Types.LifeDirection where

-- | CR 119.3: which way a life total moved. Not a Bool, for
-- Parun.Types.CostDirection's reason.
data LifeDirection
  = -- | "Gained life" (Angelic Accord).
    Gained
  | -- | "Lost life" (First Response), damage included (CR 120.3a).
    Lost
  deriving (Bounded, Enum, Eq, Ord, Show)
