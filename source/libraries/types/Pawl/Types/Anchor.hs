module Pawl.Types.Anchor where

import qualified Pawl.Types.SlotName as SlotName

-- | Which object a Pawl.Types.Filter atom relates its candidate to.
data Anchor
  = -- | CR 608.2c: the object an earlier clause bound at this slot.
    Bound SlotName.SlotName
  | -- | CR 613.4c: the object the surrounding Quantity is evaluated against.
    Evaluated
  deriving (Eq, Ord, Show)
