module Parun.Types.PlayerSacrifices where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's PlayerSacrifices arm (#1305): each player
-- the reference names sacrifices this many permanents matching the filter, in CR
-- 101.4's APNAP order -- every seat's pick is made before any of them is
-- sacrificed, which is that rule's own worked example.
data PlayerSacrifices = MkPlayerSacrifices
  { players :: PlayerRef.PlayerRef,
    filter :: Filter.Filter Keyword.Keyword,
    quantity :: Quantity.Quantity,
    -- | Where the PERMANENTS CR 701.21a sacrificed are written as a group, under
    -- the ids they held on the battlefield, so a later effect reads them off CR
    -- 608.2h's last known information -- Consume's "its power".
    -- Parun.Types.Destroy's `permanents`.
    permanents :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
