module Parun.Types.LeavingPermanent where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName

-- | CR 603.6c: which permanent a leaves-the-battlefield trigger watches leave.
data LeavingPermanent
  = -- | The bearer, compared by id against the departed one (CR 603.10a).
    Self
  | -- | A permanent the Filter admits, judged by last known information (CR 608.2h).
    Matching (Filter.Filter Keyword.Keyword)
  | -- | CR 303.4b / 301.5a: the permanent the bearer was attached to.
    Attached
  | -- | CR 702.55b: the creature the bearer haunts.
    Haunted
  | -- | CR 603.7c: the object bound at this slot as the ability was created.
    Bound SlotName.SlotName
  deriving (Eq, Ord, Show)
