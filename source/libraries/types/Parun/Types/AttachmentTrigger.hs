module Parun.Types.AttachmentTrigger where

import qualified Parun.Types.AttachDirection as AttachDirection
import qualified Parun.Types.AttachmentEnd as AttachmentEnd
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 701.3a / 701.3d: an attachment link involving the bearer was made or
-- broken -- Bramble Elemental's "whenever an Aura becomes attached to this
-- creature", Enormous Energy Blade's "whenever this Equipment becomes attached
-- to a creature", Grafted Wargear's "whenever this Equipment becomes unattached
-- from a permanent".
data AttachmentTrigger = MkAttachmentTrigger
  { -- | Which end of the link the bearer is, compared by id.
    end :: AttachmentEnd.AttachmentEnd,
    direction :: AttachDirection.AttachDirection,
    -- | The OTHER end, read through last known information (CR 608.2h).
    other :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
