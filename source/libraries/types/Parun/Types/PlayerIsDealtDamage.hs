module Parun.Types.PlayerIsDealtDamage where

import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TurnScope as TurnScope

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
    orTheirPlaneswalkers :: Bool,
    -- | CR 603.2c: EachOccurrence is one occurrence per damaged player (Lich);
    -- OneOrMore is one for the whole batch, whoever of the related players
    -- were dealt damage (Fblthp, Impossibly Lost's "one or more of your
    -- opponents").
    batching :: Batching.Batching,
    -- | CR 102.1: on whose turns the damage counts (Fblthp, Impossibly Lost's
    -- "during your turn").
    scope :: TurnScope.TurnScope
  }
  deriving (Eq, Ord, Show)

-- | "Whenever [a player] is dealt damage": each turn, once per damaged player.
-- The codec's defaults but the required `dealt`.
watching :: DealtDamage.DealtDamage PlayerRelation.PlayerRelation -> PlayerIsDealtDamage
watching d =
  MkPlayerIsDealtDamage
    { dealt = d,
      orTheirPlaneswalkers = False,
      batching = Batching.EachOccurrence,
      scope = TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer)
    }
