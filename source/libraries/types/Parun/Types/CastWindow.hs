module Parun.Types.CastWindow where

-- | Which casts a count over EventShape.SpellCast folds. Bounded and Enum for
-- Parun.Codec.CastWindow's Arm.enum.
data CastWindow
  = -- | CR 601.2i: every spell cast this turn, the event log's own extent.
    ThisTurn
  | -- | CR 601.2i: every spell cast this game (GameState.castsBeforeThisTurn).
    ThisGame
  | -- | CR 702.40a: this turn's casts before the object the count is evaluated
    -- against, so a spell cast in response isn't counted.
    BeforeEvaluated
  deriving (Bounded, Enum, Eq, Ord, Show)
