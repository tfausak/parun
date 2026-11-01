module Parun.Types.PlayerLosesLife where

import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

-- | CR 603.2 over CR 119.3's loss: whose loss counts, and how often it fires.
data PlayerLosesLife = MkPlayerLosesLife
  { player :: PlayerRelation.PlayerRelation,
    frequency :: TriggerFrequency.TriggerFrequency
  }
  deriving (Eq, Ord, Show)
