module Parun.Types.DamageTally where

import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.WhichTurn as WhichTurn

-- | CR 120.1 / 608.2i: which players were dealt damage during a turn, the
-- payload of Parun.Types.Quantity's PlayersDealtDamage.
data DamageTally = MkDamageTally
  { dealt :: DealtDamage.DealtDamage PlayerRef.PlayerRef,
    turn :: WhichTurn.WhichTurn
  }
  deriving (Eq, Ord, Show)
