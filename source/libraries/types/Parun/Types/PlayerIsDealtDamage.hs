module Parun.Types.PlayerIsDealtDamage where

import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | The payload of Parun.Types.TriggerCondition's PlayerIsDealtDamage arm: which
-- player has to be dealt the damage, and which damage counts (CR 120.1).
data PlayerIsDealtDamage = MkPlayerIsDealtDamage
  { player :: PlayerRelation.PlayerRelation,
    -- | Nothing for any damage; Just Noncombat for CR 120.2b's damage that
    -- isn't combat damage alone -- Chandra's Spitfire's "dealt noncombat
    -- damage".
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
