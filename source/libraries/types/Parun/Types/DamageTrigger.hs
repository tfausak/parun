module Parun.Types.DamageTrigger where

import qualified Data.Set as Set
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamageRecipient as DamageRecipient

-- | CR 603.2 over CR 120.1's damage: whose damage, of which kind, and to which
-- recipients.
data DamageTrigger = MkDamageTrigger
  { actor :: ActingPermanent.ActingPermanent,
    -- | Nothing for damage of any kind.
    kind :: Maybe DamageKind.DamageKind,
    -- | The recipients admitted, any one sufficing; empty for "deals damage"
    -- to anything, which is also what makes one damage event one occurrence
    -- per damager (CR 603.2c).
    recipients :: Set.Set DamageRecipient.DamageRecipient
  }
  deriving (Eq, Ord, Show)
