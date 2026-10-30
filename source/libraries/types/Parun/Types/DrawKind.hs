module Parun.Types.DrawKind where

import qualified Parun.Types.PlayerId as PlayerId

-- | CR 121.1: which draw a proposed draw is. Carried by Parun.Types.ProposedEvent's
-- WouldDraw for Chains of Mephistopheles' ruling, "A player's normal card draw on
-- their turn is exempt from this effect. All other draws will be affected."
data DrawKind
  = -- | CR 504.1: this player's turn-based draw in their draw step, kept when
    -- Plagiarize hands the draw to another player (CR 614.10).
    TurnBased PlayerId.PlayerId
  | -- | CR 121.1: any other draw, a replacement's new draws included.
    Other
  deriving (Eq, Ord, Show)
