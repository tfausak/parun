module Parun.Types.PlayerIsDealtDamage where

import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 120.3 / 603.2c: which player's damage fires the batch ability, and
-- whether that player's planeswalkers count beside them -- Lich's "whenever
-- you're dealt damage", Vengeful Pharaoh's "whenever combat damage is dealt to
-- you or a planeswalker you control".
data PlayerIsDealtDamage = MkPlayerIsDealtDamage
  { dealt :: DealtDamage.DealtDamage PlayerRelation.PlayerRelation,
    -- | "Or a planeswalker [that player] controls": damage to such a planeswalker
    -- (CR 120.3c's recipient) matches too, one occurrence per damaged
    -- planeswalker beside the player's own (Vengeful Pharaoh's ruling,
    -- 2011-09-22).
    orTheirPlaneswalkers :: Bool
  }
  deriving (Eq, Ord, Show)
