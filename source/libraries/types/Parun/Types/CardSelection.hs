module Parun.Types.CardSelection where

-- | How a card is picked where the rules leave it open: at random or by a
-- player's choice. CR 701.9b's "at random" is not a choice, so the two raise
-- different prompts and a transcript of one must not satisfy the other.
data CardSelection
  = -- | Nobody decides: Coral Helm's "discard a card at random", Tome of the
    -- Infinite\'s "conjure a random card".
    AtRandom
  | -- | A player decides: Cathartic Reunion's "discard two cards", Follow the
    -- Tracks\'s "a card of your choice".
    ByChoice
  deriving (Bounded, Enum, Eq, Ord, Show)
