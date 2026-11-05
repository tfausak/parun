module Parun.Types.CounteredKind where

-- | CR 701.6a: which of a spell or an ability was countered.
data CounteredKind
  = -- | CR 701.6a's spell, moved from the stack to its owner's graveyard.
    Spell
  | -- | CR 701.6a's ability, removed from the stack.
    Ability
  deriving (Bounded, Enum, Eq, Ord, Show)
