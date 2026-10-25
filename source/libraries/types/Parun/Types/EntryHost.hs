module Parun.Types.EntryHost where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName

-- | What the effect putting an Aura onto the battlefield says it enters
-- attached to (CR 303.4f, 303.4i).
data EntryHost
  = -- | CR 303.4i: the object the slot names (Preston Garvey, Minuteman).
    Specified SlotName.SlotName
  | -- | CR 303.4f: a host its controller chooses among those this matches as
    -- well as the Aura's enchant ability (Nomad Mythmaker).
    Chosen (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
