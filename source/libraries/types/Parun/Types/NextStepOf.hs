module Parun.Types.NextStepOf where

import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 611.2a: the payload of Parun.Types.Duration's UntilNextStepOf arm: which
-- step, of whose turn.
data NextStepOf = MkNextStepOf
  { step :: Phase.Phase,
    player :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
