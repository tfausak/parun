module Parun.Types.PlayerSacrifices where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity

-- | The payload of Parun.Types.Effect's PlayerSacrifices arm (#1305): each player
-- the reference names sacrifices this many permanents matching the filter, in CR
-- 101.4's APNAP order -- every seat's pick is made before any of them is
-- sacrificed, which is that rule's own worked example.
data PlayerSacrifices = MkPlayerSacrifices
  { players :: PlayerRef.PlayerRef,
    filter :: Filter.Filter Keyword.Keyword,
    quantity :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
