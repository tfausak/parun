module Pawl.Types.Announcement where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ModeIndex as ModeIndex
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.SlotName as SlotName

-- | CR 602.2b / 601.2b-f: what an activation was announced with, the part of
-- its game choice (CR 732.1) Action.Activate does not carry. Loop-local
-- (Pawl.Types.LoopTrail), so no codec.
data Announcement = MkAnnouncement
  { -- | CR 601.2b: the chosen modes, sorted.
    modes :: Seq.Seq ModeIndex.ModeIndex,
    -- | CR 601.2b: the announced X, if the cost has one.
    amount :: Maybe Natural.Natural,
    -- | CR 601.2f: the total cost, as it is about to be paid.
    cost :: Cost.Cost Keyword.Keyword,
    -- | CR 601.2c: the chosen targets, by slot.
    targets :: Map.Map SlotName.SlotName (Set.Set Recipient.Recipient)
  }
  deriving (Eq, Ord, Show)
