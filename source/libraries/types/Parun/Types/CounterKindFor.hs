module Parun.Types.CounterKindFor where

import qualified Parun.Types.ObjectId as ObjectId

-- | What a Parun.Types.Prompt.ChooseCounterKind answer is for.
data CounterKindFor
  = -- | CR 122.5: the kind a move takes off the first object onto the second,
    -- where the card leaves the kind open.
    MovedBetween ObjectId.ObjectId ObjectId.ObjectId
  | -- | CR 614.1c: the kind this entering object takes for one card its
    -- as-enters exile took (Frankenstein's Monster's "a +2/+0, +1/+1, or +0/+2
    -- counter").
    EnteringWith ObjectId.ObjectId
  deriving (Eq, Ord, Show)
