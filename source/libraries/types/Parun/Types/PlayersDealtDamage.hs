module Parun.Types.PlayersDealtDamage where

import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.PlayerRef as PlayerRef

-- | The payload of Parun.Types.Quantity's PlayersDealtDamageThisTurn arm: which
-- players are counted, and which damage counts (CR 120.1).
data PlayersDealtDamage = MkPlayersDealtDamage
  { player :: PlayerRef.PlayerRef,
    -- | Nothing for any damage; Just Combat for CR 510.2's combat damage
    -- alone -- Tymna the Weaver's "opponents that were dealt combat damage".
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
