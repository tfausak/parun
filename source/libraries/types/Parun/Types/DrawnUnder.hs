module Parun.Types.DrawnUnder where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.RevealTiming as RevealTiming

-- | CR 603.11 / 121.8: the object whose draw-time reveal showed a card, and when.
-- The payload of Parun.Types.RevealCause's AsDrawnUnder arm.
data DrawnUnder = MkDrawnUnder
  { under :: ObjectId.ObjectId,
    timing :: RevealTiming.RevealTiming
  }
  deriving (Eq, Ord, Show)
