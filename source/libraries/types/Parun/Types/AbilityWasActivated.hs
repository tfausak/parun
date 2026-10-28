module Parun.Types.AbilityWasActivated where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 602.2b / 601.2i: an ability became activated -- who activated it, the
-- ability on the stack, its source, and whether it is a loyalty ability (CR
-- 606.3's once-per-turn limit reads that off the log).
data AbilityWasActivated = MkAbilityWasActivated
  { player :: PlayerId.PlayerId,
    ability :: ObjectId.ObjectId,
    source :: ObjectId.ObjectId,
    loyalty :: Bool
  }
  deriving (Eq, Ord, Show)
