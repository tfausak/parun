module Parun.Types.Undoing where

-- | Why CR 734.1 reversed a cast, an activation or a combat declaration.
data Undoing
  = -- | A choice announced for it made the proposal illegal (CR 601.2e, 601.6).
    IllegalProposal
  | -- | Its total cost was not paid (CR 601.2h, 508.1j, 509.1f).
    UnpaidCost
  | -- | It repeated a game choice a fragmented loop had already made (CR 733.3).
    RepeatedLoop
  deriving (Bounded, Enum, Eq, Ord, Show)
