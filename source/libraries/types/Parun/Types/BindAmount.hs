module Parun.Types.BindAmount where

import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's BindAmount arm: the quantity, and the
-- slot its value is bound under.
data BindAmount = MkBindAmount
  { quantity :: Quantity.Quantity,
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
