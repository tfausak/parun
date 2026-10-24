module Parun.Types.PermanentActed where

import qualified Parun.Types.PermanentAction as PermanentAction

-- | CR 603.2: a permanent performed a Parun.Types.PermanentAction, beside the
-- permanent the `permanent` parameter names -- the actor's id on
-- Parun.Types.GameEvent's PermanentActed, and a Parun.Types.ActingPermanent on
-- Parun.Types.TriggerCondition's PermanentActs.
data PermanentActed permanent = MkPermanentActed
  { action :: PermanentAction.PermanentAction,
    permanent :: permanent
  }
  deriving (Eq, Ord, Show)
