module Parun.Types.AttackedSubject where

import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 508.3b / 508.3e: which attacked player or permanent fires the ability.
data AttackedSubject
  = -- | A player standing in this relation to CR 109.5's "you" -- Lulu, Stern
    -- Guardian's "attacks you".
    Related PlayerRelation.PlayerRelation
  | -- | CR 303.4b: the player this ability's source enchants.
    Enchanted
  | -- | CR 508.3b: the ability's own source, a planeswalker or battle.
    Source
  deriving (Eq, Ord, Show)
