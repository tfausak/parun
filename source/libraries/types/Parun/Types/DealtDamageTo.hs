module Parun.Types.DealtDamageTo where

import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagedParty as DamagedParty
import qualified Parun.Types.Lookback as Lookback

-- | The payload of Parun.Types.Filter's DealtDamageTo arm: whom the candidate
-- dealt damage to, which damage counts (CR 120.1), and how far back.
data DealtDamageTo = MkDealtDamageTo
  { party :: DamagedParty.DamagedParty,
    -- | Nothing for any damage; Just Combat for CR 510.2's combat damage
    -- alone -- Witch-king of Angmar's "dealt combat damage to you".
    kind :: Maybe DamageKind.DamageKind,
    -- | The turn in progress, or every turn the candidate has been this object.
    window :: Lookback.Lookback
  }
  deriving (Eq, Ord, Show)
