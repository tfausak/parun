module Parun.Types.RevealTiming where

-- | CR 121.8: when a draw-time reveal showed its card.
data RevealTiming
  = -- | CR 121.9: as the card was drawn.
    AsDrawn
  | -- | CR 121.8: once the spell being cast became cast, or the ability being
    -- activated became activated, the card having been kept face down.
    OnceCast
  deriving (Bounded, Enum, Eq, Ord, Show)
