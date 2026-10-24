module Parun.Types.Visibility where

-- | Whether a player may see an object's face now (CR 400.2).
data Visibility
  = -- | CR 400.2: the player may see it.
    Visible
  | -- | CR 400.2: the player may not.
    Obscured
  deriving (Bounded, Enum, Eq, Ord, Show)

-- | Visible wins: a player sees an object when any reason lets them.
instance Semigroup Visibility where
  left <> right = case left of
    Visible -> Visible
    Obscured -> right

instance Monoid Visibility where
  mempty = Obscured
