module Pawl.Types.RevealWindow where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.ObjectId as ObjectId

-- | How long a lasting reveal lasts (CR 701.20a).
data RevealWindow
  = -- | CR 701.20a: until that spell or ability leaves the stack.
    WhileOnStack ObjectId.ObjectId
  | -- | CR 701.20a: until the next time a player would receive priority.
    UntilPriority
  | -- | CR 103.6b: until the first turn begins.
    UntilFirstTurn
  | -- | CR 702.57b: until a step that isn't that turn's upkeep begins.
    DuringUpkeep Natural.Natural
  deriving (Eq, Ord, Show)
