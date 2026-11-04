module Parun.Types.LifeTrigger where

import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TurnScope as TurnScope

-- | CR 603.2 over CR 119.3's gain or loss: which way, whose counts, on whose
-- turn, per occurrence or per batch (CR 603.2c), and how often it fires.
data LifeTrigger = MkLifeTrigger
  { direction :: LifeDirection.LifeDirection,
    player :: PlayerRelation.PlayerRelation,
    scope :: TurnScope.TurnScope,
    batching :: Batching.Batching,
    frequency :: TriggerFrequency.TriggerFrequency
  }
  deriving (Eq, Ord, Show)
