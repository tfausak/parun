module Pawl.Types.TurnRole where

-- | Which seats a role the turn hands out names: the player(s) a filter or a
-- player choice asks for by role rather than by relation to "you".
data TurnRole
  = -- | CR 102.1 / 805.4a: the active player, or every member of the active team
    -- under the shared team turns option.
    Active
  | -- | CR 506.2 / 508.5: the defending player.
    Defending
  deriving (Bounded, Enum, Eq, Ord, Show)
