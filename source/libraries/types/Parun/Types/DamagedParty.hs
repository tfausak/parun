module Parun.Types.DamagedParty where

import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

-- | CR 120.1: whom a candidate dealt damage to, for Filter.DealtDamageTo.
data DamagedParty
  = -- | A player standing in this relation to CR 109.5's "you" -- Reciprocate's
    -- "dealt damage to you".
    Related PlayerRelation.PlayerRelation
  | -- | The evaluation's source -- Brine Hag's "dealt damage to it".
    Source
  | -- | An object this slot binds -- Hawkeye, Avenging Archer's "dealt damage to
    -- it", the creature a dies trigger names (CR 603.10a).
    InSlot SlotName.SlotName
  | -- | Any player or object at all -- Palladia-Mors, the Ruiner's "hasn't dealt
    -- damage yet".
    Anyone
  deriving (Eq, Ord, Show)
