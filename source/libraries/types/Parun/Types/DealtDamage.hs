module Parun.Types.DealtDamage where

import qualified Parun.Types.DamageKind as DamageKind

-- | Which player was dealt damage, and which damage counts (CR 120.1).
-- PARAMETRIC in how the player is named: a Parun.Types.PlayerRelation in
-- Parun.Types.PlayerIsDealtDamage's dealt, a Parun.Types.PlayerRef
-- in Parun.Types.Quantity's PlayersDealtDamageThisTurn.
data DealtDamage player = MkDealtDamage
  { player :: player,
    -- | Nothing for any damage; Just Combat for CR 510.2's combat damage alone
    -- (Tymna the Weaver), Just Noncombat for CR 120.2b's other damage
    -- (Chandra's Spitfire).
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
