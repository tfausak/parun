module Parun.Types.ControlWindow where

-- | How far back Parun.Types.Quantity's ControlGained looks for a player coming
-- to control an object.
data ControlWindow
  = -- | CR 702.30a: since the beginning of that player's last upkeep.
    SinceLastUpkeep
  | -- | CR 110.2 / 608.2i: this turn, an entry under that player's control
    -- included (Erg Raiders' ruling).
    ThisTurn
  deriving (Bounded, Enum, Eq, Ord, Show)
