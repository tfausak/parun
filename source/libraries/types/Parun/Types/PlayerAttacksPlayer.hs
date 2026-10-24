module Parun.Types.PlayerAttacksPlayer where

import qualified Parun.Types.AttackedPlayer as AttackedPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 508.3e: which player's declaration fires the ability, and which player
-- it has to have been aimed at -- Lulu, Stern Guardian's "whenever an opponent
-- attacks you".
--
-- A record for Parun.Types.PlayerAttacksWith's reason: rule 508.3e's printed
-- form names two subjects, and a bare pair of relations reads the same in
-- either order at every pattern site.
data PlayerAttacksPlayer = MkPlayerAttacksPlayer
  { attacker :: PlayerRelation.PlayerRelation,
    attacked :: AttackedPlayer.AttackedPlayer
  }
  deriving (Eq, Ord, Show)
