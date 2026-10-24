module Parun.Types.ThrowKind where

import qualified Numeric.Natural as Natural

-- | What a Parun.Types.Throw throws: CR 705.1's coins or CR 706.1's dice.
data ThrowKind
  = -- | CR 705.1: coins.
    Coins
  | -- | CR 706.1a: dice with this many sides.
    Dice Natural.Natural
  deriving (Eq, Ord, Show)
