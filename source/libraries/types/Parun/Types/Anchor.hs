module Parun.Types.Anchor where

import qualified Parun.Types.SlotName as SlotName

-- | Which object a Parun.Types.Filter atom relates its candidate to. Parametric
-- in the filter, so the group arm can hold one without a module cycle.
data Anchor nested
  = -- | CR 608.2c: the object an earlier clause bound at this slot.
    Bound SlotName.SlotName
  | -- | CR 613.4c: the object the surrounding Quantity is evaluated against.
    Evaluated
  | -- | CR 113.7: the source of the ability or effect the match is made for.
    Source
  | -- | CR 109.2: any one permanent this filter admits, read against the outer match's context.
    AnyPermanent nested
  deriving (Eq, Ord, Show)
