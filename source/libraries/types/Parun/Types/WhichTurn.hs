module Parun.Types.WhichTurn where

-- | CR 500.1 / 608.2i: which turn's history a tally reads -- the turn in progress, or the
-- one before it, whoever's it was ("last turn", Feast on the Fallen).
data WhichTurn
  = -- | The turn in progress, GameState.events.
    ThisTurn
  | -- | The turn before it, GameState.eventsLastTurn: on the game's first turn,
    -- whatever the log held before that turn began.
    LastTurn
  deriving (Bounded, Enum, Eq, Ord, Show)
