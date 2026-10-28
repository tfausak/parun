module Parun.Types.ActivationsThisTurn where

import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef

-- | Which of the turn's activations (CR 602.2) a Parun.Types.Quantity's
-- ActivationsThisTurn counts: The Chain Veil's "you activate a loyalty ability
-- of a planeswalker".
data ActivationsThisTurn = MkActivationsThisTurn
  { -- | CR 602.2a: the player who activated it.
    activator :: PlayerRef.PlayerRef,
    -- | Asked of the ability's source as the activation began (CR 608.2i).
    source :: Filter.Filter Keyword.Keyword,
    -- | What only the ability, not its source, can answer.
    criteria :: ActivationCriteria.ActivationCriteria
  }
  deriving (Eq, Ord, Show)
