module Pawl.Types.DealtDamageTo where

import qualified Pawl.Types.DamageKind as DamageKind
import qualified Pawl.Types.DamagedParty as DamagedParty

-- | The payload of Pawl.Types.Filter's DealtDamageToThisTurn arm: whom the
-- candidate dealt damage to, and which damage counts (CR 120.1).
data DealtDamageTo = MkDealtDamageTo
  { party :: DamagedParty.DamagedParty,
    -- | Nothing for any damage; Just Combat for CR 510.2's combat damage
    -- alone -- Witch-king of Angmar's "dealt combat damage to you".
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
