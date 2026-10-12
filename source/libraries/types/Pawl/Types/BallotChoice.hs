module Pawl.Types.BallotChoice where

import qualified Pawl.Types.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Types.SlotName as SlotName

-- | What one vote was cast for (CR 701.38b).
data BallotChoice
  = -- | An object, as it stood when voted for, so a ballot still names an object that has since left (CR 701.38b).
    ForObject ObjectSnapshot.ObjectSnapshot
  | -- | A word with no rules meaning (CR 701.38b).
    ForWord SlotName.SlotName
  deriving (Eq, Ord, Show)
