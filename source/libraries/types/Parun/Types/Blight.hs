module Parun.Types.Blight where

import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Blight arm: CR 701.68a's "these players,
-- this many", plus the name CR 701.68c's "blighted creature" is read under.
--
-- Parun.Types.PlayerQuantity's two fields with one more, SPUN OUT rather than
-- bolted onto that record, which is the rule that record's own haddock states.
-- Parun.Types.Mill and Parun.Types.LifeLoss left the same way.
data Blight = MkBlight
  { player :: PlayerRef.PlayerRef,
    quantity :: Quantity.Quantity,
    -- | CR 701.68c: the creature the blighting player chose to put the counters
    -- on, bound for a later effect of the same resolution to name -- Grub,
    -- Notorious Auntie's "a token that's a copy of the blighted creature".
    -- Absent for every blight nothing looks back at.
    --
    -- ACROSS blighters, since the slot is one name and no reader is per-player:
    -- one blighted creature takes the single binding every singular reader can
    -- see and several take the group, which is Parun.Types.Mill's `slot` posture.
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
