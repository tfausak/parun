module Parun.Types.DealsDamageToPlayer where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 603.2 / 120.1: which permanent's or spell's damage fires the ability,
-- and which player it has to have been dealt to -- Akki Lavarunner's
-- "whenever this creature deals damage to an opponent", Curiosity's "whenever
-- enchanted creature deals damage to an opponent", Chandra's Phoenix's "dealt
-- damage by a red instant or sorcery spell you control". The scenario
-- chandras-phoenix-returns-when-a-red-spell-burns-an-opponent proves the
-- spell.
data DealsDamageToPlayer = MkDealsDamageToPlayer
  { actor :: ActingPermanent.ActingPermanent,
    recipient :: PlayerRelation.PlayerRelation,
    -- | Nothing for damage of any kind; Just Noncombat for Chandra's Pyreling's
    -- "deals noncombat damage".
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
