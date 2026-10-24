module Parun.Types.KeywordInstance where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 702.174a / 611.3a: which one of an object's identical instances of a
-- keyword this is, stable for as long as the instance exists, so a record made
-- for one instance is not inherited by another when an instance stops applying.
-- Parun.Engine.Projection.keywordInstances lists an object's.
data KeywordInstance
  = -- | The nth of the object's own instances, counting from 1: printed or
    -- copied onto it, or, on a permanent, entered with (CR 400.7d).
    Own Natural.Natural
  | -- | CR 613.7a: the nth instance, counting from 1, granted by the effect
    -- from this source with this timestamp.
    Granted ObjectId.ObjectId Timestamp.Timestamp Natural.Natural
  deriving (Eq, Ord, Show)
