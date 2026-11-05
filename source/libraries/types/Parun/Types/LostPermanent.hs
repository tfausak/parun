module Parun.Types.LostPermanent where

import qualified Parun.Types.SlotName as SlotName

-- | CR 603.10d / 603.7: which permanent a lose-control trigger watches change
-- hands away from "you".
data LostPermanent
  = -- | CR 603.10d: the bearer itself (Khârn, the Betrayer).
    Self
  | -- | CR 603.7c: the object bound at this slot as the ability was created (Ray
    -- of Command).
    Bound SlotName.SlotName
  deriving (Eq, Ord, Show)
