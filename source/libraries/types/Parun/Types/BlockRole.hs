module Parun.Types.BlockRole where

-- | CR 506.3: which side of combat a creature stands on -- attacking, or
-- blocking an attacker.
data BlockRole
  = -- | CR 508.1a: an attacking creature, or the one a blocker blocks.
    Attacker
  | -- | CR 509.1a: a blocking creature.
    Blocker
  deriving (Bounded, Enum, Eq, Ord, Show)
