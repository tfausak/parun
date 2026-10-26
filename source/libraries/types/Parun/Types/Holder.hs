module Parun.Types.Holder where

-- | Which of a candidate's players a Parun.Types.Filter holder atom reads.
data Holder
  = -- | CR 108.4 / 110.2: its controller.
    Controller
  | -- | CR 108.3: its owner.
    Owner
  deriving (Bounded, Enum, Eq, Ord, Show)
