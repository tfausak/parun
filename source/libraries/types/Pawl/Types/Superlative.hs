module Pawl.Types.Superlative where

import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.PlayerMeasure as PlayerMeasure

-- | The players whose measure stands in @comparison@ to EVERY other player's.
-- GreaterThan is Damping Engine's strict "more permanents than each other
-- player", so a tie names nobody; AtLeast is Raiders' Allegiance's "the most
-- point counters or tied for the most".
--
-- PERSPECTIVE-FREE: the sentence names no "you", so the set is a fact about the
-- board, read by Pawl.Engine.Players.superlative.
data Superlative = MkSuperlative
  { measure :: PlayerMeasure.PlayerMeasure,
    comparison :: Comparison.Comparison
  }
  deriving (Eq, Ord, Show)
