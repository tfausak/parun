module Parun.Types.PermanentDealsCombatDamageToPlayer where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 603.2 / 510.2: which permanent's combat damage fires the ability, and
-- which player it has to have been dealt to -- Teysa, Envoy of Ghosts'
-- "whenever a creature deals combat damage to you".
--
-- Not Parun.Types.PermanentsDealCombatDamageToPlayer: that record's
-- `oneOrMorePlayers` has no singular reading.
data PermanentDealsCombatDamageToPlayer = MkPermanentDealsCombatDamageToPlayer
  { filter :: Filter.Filter Keyword.Keyword,
    recipient :: PlayerRelation.PlayerRelation,
    -- | "Or planeswalker": combat damage to a planeswalker a player the
    -- recipient relation admits controls (CR 120.3c) matches too, Hunter's
    -- Insight's "a player or planeswalker". Parun.Types.PlayerIsDealtDamage's
    -- field of the same name, with the damager filtered.
    orTheirPlaneswalkers :: Bool
  }
  deriving (Eq, Ord, Show)
