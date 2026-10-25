module Parun.Types.LandOrNonland where

-- | "Choose land or nonland" (Abundance): which kind of card is wanted, by CR
-- 205.2a's land card type.
data LandOrNonland
  = -- | CR 205.2a: a card with the land card type.
    Land
  | -- | CR 205.2a: a card without it.
    Nonland
  deriving (Bounded, Enum, Eq, Ord, Show)
