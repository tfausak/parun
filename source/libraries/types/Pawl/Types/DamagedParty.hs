module Pawl.Types.DamagedParty where

import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | CR 120.1: whom a candidate dealt damage to, for Filter.DealtDamageToThisTurn.
data DamagedParty
  = -- | A player standing in this relation to CR 109.5's "you" -- Reciprocate's
    -- "dealt damage to you".
    Related PlayerRelation.PlayerRelation
  | -- | The evaluation's source -- Brine Hag's "dealt damage to it".
    Source
  deriving (Eq, Ord, Show)
