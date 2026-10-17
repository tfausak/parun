module Pawl.Types.PlayerMeasure where

import qualified Pawl.Types.PlayerCounterKind as PlayerCounterKind

-- | A number every player has, for Pawl.Types.Superlative to compare across
-- the table.
data PlayerMeasure
  = -- | CR 110.1 / 613.1b: how many permanents the player controls.
    PermanentsControlled
  | -- | CR 122.1: how many counters of this kind the player has.
    CountersOf PlayerCounterKind.PlayerCounterKind
  deriving (Eq, Ord, Show)
