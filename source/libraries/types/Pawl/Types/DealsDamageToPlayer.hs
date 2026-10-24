module Pawl.Types.DealsDamageToPlayer where

import qualified Pawl.Types.ActingPermanent as ActingPermanent
import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | CR 603.2 / 120.1: which permanent's damage of any kind fires the ability,
-- and which player it has to have been dealt to -- Akki Lavarunner's "whenever
-- this creature deals damage to an opponent", Curiosity's "whenever enchanted
-- creature deals damage to an opponent".
data DealsDamageToPlayer = MkDealsDamageToPlayer
  { actor :: ActingPermanent.ActingPermanent,
    recipient :: PlayerRelation.PlayerRelation
  }
  deriving (Eq, Ord, Show)
