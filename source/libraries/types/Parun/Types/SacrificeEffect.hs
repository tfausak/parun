module Parun.Types.SacrificeEffect where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Sacrifice arm (CR 701.21): which
-- permanents are sacrificed, and which player is instructed to sacrifice each.
--
-- Distinct from Parun.Types.Sacrifice, which is the same keyword action as a COST
-- -- that one counts matching permanents its payer chooses, where this one names
-- the permanents through its ObjectRef, whose ChosenPermanents arm is the one
-- choice (CR 608.2d, God-Eternal Bontu).
data SacrificeEffect = MkSacrificeEffect
  { -- | ObjectRef and not a bare SlotName so a filtered sweep of the battlefield
    -- reaches CR 701.21a -- Golgothian Sylex's "each nontoken permanent with a
    -- name originally printed in the Antiquities expansion", and City in a
    -- Bottle's own sweep. InSlot is the arm most of the pool writes.
    ref :: ObjectRef.ObjectRef,
    -- | CR 701.21a: whom the printed sentence addresses.
    sacrificer :: Sacrificer.Sacrificer,
    -- | Where the count of what CR 701.21a actually sacrificed is written, for a
    -- later effect of the same resolution to read as Quantity.InSlot -- God-Eternal
    -- Bontu's "then draw that many cards". Parun.Types.Destroy's `slot`.
    sacrificed :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
