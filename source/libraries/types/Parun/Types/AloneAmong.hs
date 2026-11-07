module Parun.Types.AloneAmong where

-- | Which other declared attackers make a creature not alone.
data AloneAmong
  = -- | CR 506.5: every other creature declared as an attacker.
    EveryAttacker
  | -- | CR 506.6: it attacks a player, and no other creature declared
    -- attacks that player.
    AttackersOfItsPlayer
  deriving (Bounded, Enum, Eq, Ord, Show)
