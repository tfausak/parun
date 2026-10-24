module Parun.Types.ReturnEnding where

import qualified Parun.Types.MonarchWatch as MonarchWatch
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 610.3's specified event for one moved object, armed from the move's
-- Parun.Types.MoveDuration with what the game must remember to see it happen.
data ReturnEnding
  = -- | CR 610.3 / 400.7: this incarnation of the move's source leaves the battlefield.
    SourceLeaves ObjectId.ObjectId
  | -- | CR 725: an opponent of the watch's controller becomes the monarch.
    OpponentCrowned MonarchWatch.MonarchWatch
  deriving (Eq, Ord, Show)
