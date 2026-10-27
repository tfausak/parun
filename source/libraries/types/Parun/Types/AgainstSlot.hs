module Parun.Types.AgainstSlot where

import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Quantity's AgainstSlot arm (#1305): which object
-- to aim at, then what to read off it.
--
-- PARAMETRIC in the quantity for Parun.Types.Plus's reason: the inner value is a
-- whole Quantity and Quantity names this record.
--
-- Distinct from Quantity's InSlot, which reads an AMOUNT an earlier effect bound
-- at a slot: this names an OBJECT slot and reads a characteristic off whatever it
-- points at, which is why it carries a quantity where InSlot carries nothing.
data AgainstSlot quantity = MkAgainstSlot
  { slot :: SlotName.SlotName,
    quantity :: quantity
  }
  deriving (Eq, Ord, Show)
