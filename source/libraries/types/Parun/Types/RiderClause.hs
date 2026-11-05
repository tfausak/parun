module Parun.Types.RiderClause where

import Numeric.Natural (Natural)

-- | Which clause of a keyword ability's printed rider (CR 602.5) a
-- Parun.Types.KeywordRiderGrant relaxes.
data RiderClause
  = -- | CR 602.5d read as CR 602.5e: activate any time the player could cast
    -- an instant (Leonin Shikari).
    InstantSpeed
  | -- | CR 602.5b's per-turn limit raised to this many (Birgi, God of
    -- Storytelling).
    TimesEachTurn Natural
  deriving (Eq, Ord, Show)
