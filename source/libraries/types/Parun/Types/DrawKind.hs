module Parun.Types.DrawKind where

-- | CR 121.1: which draw a proposed draw is. Carried by Parun.Types.ProposedEvent's
-- WouldDraw for Chains of Mephistopheles' ruling, "A player's normal card draw on
-- their turn is exempt from this effect. All other draws will be affected."
data DrawKind
  = -- | CR 504.1: the active player's turn-based draw in their draw step.
    TurnBased
  | -- | CR 121.1: any other draw, a replacement's included.
    Other
  deriving (Bounded, Enum, Eq, Ord, Show)
