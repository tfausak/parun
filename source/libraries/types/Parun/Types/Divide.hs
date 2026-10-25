module Parun.Types.Divide where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Divide arm: CR 608.2d's division of an
-- amount among any number of the untargeted objects a ref names, each chosen
-- one getting at least one, bound for a later instruction to read as
-- Quantity.Share -- Master of the Wild Hunt's "damage equal to its power
-- divided as its controller chooses among any number of those Wolves".
--
-- The CHOOSER is a PlayerRef naming ONE seat, Parun.Types.ChooseNumber's
-- reading; a ref naming no seat divides nothing (CR 101.3).
data Divide = MkDivide
  { quantity :: Quantity.Quantity,
    among :: ObjectRef.ObjectRef,
    chooser :: PlayerRef.PlayerRef,
    -- | Where the chosen objects are bound, as a group, each with its part
    -- (Binding.division). Nothing is bound where nothing is divided.
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
