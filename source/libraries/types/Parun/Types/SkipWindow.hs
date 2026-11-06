module Parun.Types.SkipWindow where

import qualified Parun.Types.PhaseSelector as PhaseSelector

-- | CR 500.11 / 614.10: what a skip names, and what Parun.Engine.Engine offers
-- up as it is about to begin. The two sides of CR 614.1b are compared by
-- EQUALITY on this type.
--
-- A type of its own rather than a fourth PhaseSelector arm: a PhaseSelector
-- also names an activation window and an expiry, where a whole turn is no
-- window, and an extra turn's own skips (Parun.Types.TakeExtraTurn) can't name
-- the turn itself.
data SkipWindow
  = -- | A step or phase of the turn (CR 500.1).
    PartOfTurn PhaseSelector.PhaseSelector
  | -- | The whole turn (CR 500.11).
    WholeTurn
  deriving (Eq, Ord, Show)
