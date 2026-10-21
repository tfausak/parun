module Pawl.Types.ChooseNumber where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.SlotName as SlotName

-- | The payload of Pawl.Types.Effect's ChooseNumber arm: where the number is
-- bound, and the most it may be -- Trade Secrets' "draw up to four cards"
-- beside Rites of Initiation's unbounded "any number" (CR 107.1c).
--
-- The CHOOSER is a PlayerRef naming ONE seat, Pawl.Types.ChosenPermanents'
-- reading: CR 608.2c's default is the resolving controller, @Relative You@, and
-- Temporary Truce's "each player may draw up to two cards" is a CR 608.2f loop
-- over the players whose body has the member choose, @InSlot@ the loop's slot.
-- A ref naming no seat names no number, and the instruction is ignored (CR
-- 101.3).
data ChooseNumber = MkChooseNumber
  { slot :: SlotName.SlotName,
    upTo :: Maybe Natural.Natural,
    chooser :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
