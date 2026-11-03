module Parun.Types.LifeTrigger where

import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

-- | CR 603.2 over CR 119.3's gain or loss: whose counts, and how often it fires.
data LifeTrigger = MkLifeTrigger
  { player :: PlayerRelation.PlayerRelation,
    frequency :: TriggerFrequency.TriggerFrequency
  }
  deriving (Eq, Ord, Show)
