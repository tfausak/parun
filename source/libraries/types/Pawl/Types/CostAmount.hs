module Pawl.Types.CostAmount where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.SlotName as SlotName

-- | How much of a resource one Pawl.Types.CostComponent asks for: a printed
-- number, or a value CR 601.2b announces and Pawl.Engine.Cost.substituteAnnounced
-- fixes.
data CostAmount
  = -- | A number printed on the card, or one an announcement already fixed.
    Fixed Natural.Natural
  | -- | CR 107.3a / 601.2b: a variable not yet announced, bound under this slot:
    -- Pawl.Engine.Binding.variableX for X, or a name of its own for a count
    -- announced beside it (March of Wretched Sorrow's "any number of black cards").
    Announced SlotName.SlotName
  deriving (Eq, Ord, Show)
