module Pawl.Types.BallotChoice where

import qualified Pawl.Types.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Types.SlotName as SlotName

-- | What one vote was cast for (CR 701.38b).
data BallotChoice
  = -- | An object (CR 701.38b), snapshotted when voted for so a ballot still names one that has since left.
    ForObject ObjectSnapshot.ObjectSnapshot
  | -- | A word with no rules meaning (CR 701.38b).
    ForWord SlotName.SlotName
  deriving (Eq, Ord, Show)
