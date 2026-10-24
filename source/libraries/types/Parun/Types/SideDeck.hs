module Parun.Types.SideDeck where

-- | A supplementary deck a player brings beside their library, which begins
-- the game in the command zone rather than among the deck's cards. One
-- parameter rather than a field apiece on Parun.Types.Deck and
-- Parun.Types.GameState, since every one of them is held the same way: a
-- face-down pile per player, head on top, shuffled before the game begins (CR
-- 103.3a).
data SideDeck
  = -- | CR 717.2: the Attraction deck.
    Attraction
  | -- | The Contraption deck, from the Unstable FAQ rather than the rules: CR
    -- 701.45a leaves Unstable's mechanics out of them.
    Contraption
  | -- | CR 901.3: the planar deck.
    Planar
  | -- | CR 904.3: the scheme deck.
    Scheme
  deriving (Bounded, Enum, Eq, Ord, Show)
