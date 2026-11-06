module Parun.Types.Undoing where

-- | Why CR 733.1 reversed a cast or an activation.
data Undoing
  = -- | A choice announced for it made the proposal illegal (CR 601.2e, 601.6).
    IllegalProposal
  | -- | Its total cost was not paid (CR 601.2h).
    UnpaidCost
  deriving (Bounded, Enum, Eq, Ord, Show)
