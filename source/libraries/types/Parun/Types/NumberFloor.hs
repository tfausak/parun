module Parun.Types.NumberFloor where

-- | What a Prompt.ChooseNumber's floor means to its answer.
data NumberFloor
  = -- | CR 608.2d: the least answer the choice allows.
    Least
  | -- | CR 608.2d: the high bid; an answer not above it declines to top it.
    HighBid
  deriving (Bounded, Enum, Eq, Ord, Show)
