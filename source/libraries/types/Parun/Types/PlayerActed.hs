module Parun.Types.PlayerActed where

import qualified Parun.Types.PlayerAction as PlayerAction

-- | CR 603.2: a player performed a Parun.Types.PlayerAction, beside the player
-- the `player` parameter names -- the actor itself on Parun.Types.GameEvent's
-- PlayerActed, and a Parun.Types.PlayerRelation to CR 109.5's "you" on
-- Parun.Types.TriggerCondition's PlayerActs.
data PlayerActed player = MkPlayerActed
  { action :: PlayerAction.PlayerAction,
    player :: player
  }
  deriving (Eq, Ord, Show)
