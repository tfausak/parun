module Parun.Types.OutsidePick where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 608.2d: which seat chooses among the cards a
-- 'Parun.Types.FromOutsideTheGame.FromOutsideTheGame' revealed, and how many it
-- chooses -- Extrapolate the Impossible's "An opponent chooses one of them".
-- Only the chosen cards come in; the rest stay outside the game.
--
-- Held inside the one instruction rather than bound to a slot for
-- 'Parun.Types.ChosenCardFromAmong.ChosenCardFromAmong': a card outside the
-- game is no object (CR 400.11), so a slot has nothing to bind.
data OutsidePick = MkOutsidePick
  { -- | Who chooses, relative to the player bringing the cards in (CR 102.2).
    chooser :: PlayerRelation.PlayerRelation,
    -- | How many of the revealed cards the chooser picks.
    count :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
