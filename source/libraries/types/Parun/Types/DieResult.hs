module Parun.Types.DieResult where

import qualified Numeric.Natural as Natural

-- | CR 706.2: one die's result, after every modifier, beside the player the
-- `player` parameter names -- the roller itself on Parun.Types.GameEvent's
-- DieResultSettled, and a Parun.Types.PlayerRelation to CR 109.5's "you" on
-- Parun.Types.TriggerCondition's PlayerRollsResult (Night Shift of the Living
-- Dead's "whenever you roll a 6").
data DieResult player = MkDieResult
  { roller :: player,
    result :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
