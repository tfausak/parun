module Parun.Types.DeclarationTrigger where

import qualified Parun.Types.AttackCount as AttackCount
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 508.3c / 508.3d: which player's declaration fires the ability, and the
-- creatures it has to have declared -- Nothing for CR 508.3d's "whenever [a
-- player] attacks", a count for Hermes, Overseer of Elpis' "whenever you
-- attack with one or more Birds".
data DeclarationTrigger = MkDeclarationTrigger
  { player :: PlayerRelation.PlayerRelation,
    attackers :: Maybe AttackCount.AttackCount
  }
  deriving (Eq, Ord, Show)
