module Parun.Types.CounterR where

import qualified Parun.Types.CounterPattern as CounterPattern
import qualified Parun.Types.Scaling as Scaling

-- | The payload of Parun.Types.ReplacementEffect's CounterR arm (#1305): which
-- counter placements are intercepted, and how the number placed is scaled.
data CounterR = MkCounterR
  { matching :: CounterPattern.CounterPattern,
    scaling :: Scaling.Scaling
  }
  deriving (Eq, Ord, Show)
