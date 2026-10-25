module Parun.Types.BlockRole where

-- | CR 509.1g: which side of a blocking relation an object stands on -- the
-- attacking creature that is blocked, or the creature blocking it.
data BlockRole
  = -- | CR 509.1g: the attacking creature a blocker blocks.
    Attacker
  | -- | CR 509.1g: a creature declared blocking an attacker.
    Blocker
  deriving (Bounded, Enum, Eq, Ord, Show)
