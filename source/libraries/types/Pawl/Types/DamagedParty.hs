module Pawl.Types.DamagedParty where

import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.SlotName as SlotName

-- | CR 120.1: whom a candidate dealt damage to, for Filter.DealtDamageToThisTurn.
data DamagedParty
  = -- | A player standing in this relation to CR 109.5's "you" -- Reciprocate's
    -- "dealt damage to you".
    Related PlayerRelation.PlayerRelation
  | -- | The evaluation's source -- Brine Hag's "dealt damage to it".
    Source
  | -- | An object this slot binds -- Hawkeye, Avenging Archer's "dealt damage to
    -- it", the creature a dies trigger names (CR 603.10a).
    InSlot SlotName.SlotName
  deriving (Eq, Ord, Show)
