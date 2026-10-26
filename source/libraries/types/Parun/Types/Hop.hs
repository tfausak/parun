module Parun.Types.Hop where

-- | Which object a Parun.Types.PlayerRef.HolderOfBound reads the holder of: the
-- one its slot names, or the permanent that one is attached to.
data Hop
  = -- | The object the slot names.
    Itself
  | -- | CR 303.4b / 301.5a: the object it is attached to.
    Host
  deriving (Bounded, Enum, Eq, Ord, Show)
