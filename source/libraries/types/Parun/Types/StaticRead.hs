module Parun.Types.StaticRead where

-- | What a static walk over a card's quantities and effects looks for
-- (Parun.Engine.Quantity.hasRead, Parun.Engine.Resolve.Slots.hasRead).
data StaticRead
  = -- | CR 107.3: the value of X.
    ReadsX
  | -- | CR 107.3 / 601.2h: the mana spent on X (Soul Burn, Illusionary Mask).
    ReadsManaSpentOnX
  deriving (Eq, Ord, Show)
