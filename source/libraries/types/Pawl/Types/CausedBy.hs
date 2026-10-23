module Pawl.Types.CausedBy where

import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | CR 603.2 / 609.1: a trigger condition narrowed to the events a spell or
-- ability's effect caused, whose controller relates thus to CR 109.5's "you" --
-- Sacred Ground's "a spell or ability an opponent controls causes a land to be
-- put into your graveyard from the battlefield".
--
-- PARAMETRIC in the condition it narrows, Pawl.Types.PlayerActed's posture, so
-- Pawl.Types.TriggerCondition can hold one without a module cycle.
data CausedBy condition = MkCausedBy
  { controller :: PlayerRelation.PlayerRelation,
    condition :: condition
  }
  deriving (Eq, Ord, Show)
