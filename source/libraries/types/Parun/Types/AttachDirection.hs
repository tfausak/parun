module Parun.Types.AttachDirection where

-- | CR 701.3a / 701.3d: whether a link was made or broken.
data AttachDirection
  = -- | CR 701.3a: "becomes attached".
    Attaches
  | -- | CR 701.3d: "becomes unattached".
    Unattaches
  deriving (Bounded, Enum, Eq, Ord, Show)
