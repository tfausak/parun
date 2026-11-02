module Parun.Types.DealtDamage where

import qualified Parun.Types.DamageKind as DamageKind

-- | What was dealt damage, and which damage counts (CR 120.1). PARAMETRIC in
-- how the recipient is named: a Parun.Types.PlayerRelation in
-- Parun.Types.PlayerIsDealtDamage's dealt, a Parun.Types.PlayerRef in
-- Parun.Types.Quantity's PlayersDealtDamageThisTurn and
-- DamageDealtToPlayersThisTurn, a
-- Parun.Types.ActingPermanent in Parun.Types.TriggerCondition's IsDealtDamage.
data DealtDamage recipient = MkDealtDamage
  { recipient :: recipient,
    -- | Nothing for any damage; Just Combat for CR 510.2's combat damage alone
    -- (Tymna the Weaver, Wall of Essence), Just Noncombat for CR 120.2b's other
    -- damage (Chandra's Spitfire, Chandra's Incinerator).
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
