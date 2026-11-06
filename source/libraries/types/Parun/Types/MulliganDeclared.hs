module Parun.Types.MulliganDeclared where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.MulliganDecision as MulliganDecision
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 103.5: a player declared whether they will take a mulligan, in public.
data MulliganDeclared = MkMulliganDeclared
  { player :: PlayerId.PlayerId,
    decision :: MulliganDecision.MulliganDecision,
    -- | CR 103.5 / 103.5c: the cards this mulligan puts on the bottom, as
    -- Parun.Engine.Mulligan.offerFor promised; 0 on a keep.
    bottomCount :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
