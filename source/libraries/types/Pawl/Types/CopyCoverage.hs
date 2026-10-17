module Pawl.Types.CopyCoverage where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Timestamp as Timestamp

-- | Which objects a stored copy effect (Pawl.Types.ActiveCopy) covers,
-- answered by Pawl.Engine.Game.copyCovers.
data CopyCoverage
  = -- | CR 611.2c: the objects the effect named as it began, fixed thereafter.
    These (Set.Set ObjectId.ObjectId)
  | -- | CR 611.3a / 303.4m / 301.5f: whatever the row's source is attached to
    -- while it is on the battlefield, read live. The map holds each object a
    -- later copy effect took over (CR 613.7), with the source's timestamp at
    -- that moment: a re-attachment restamps the source (CR 613.7e), and the row
    -- covers that object again.
    SourceHost (Map.Map ObjectId.ObjectId Timestamp.Timestamp)
  deriving (Eq, Ord, Show)
