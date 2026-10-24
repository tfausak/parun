module Parun.Types.RemoveCounters where

import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's RemoveCounters arm (#1305).
--
-- PutCounters' mirror, but NOT a shared record with it: this names a slot where
-- that names an ObjectRef, so the two coincide in two fields out of three and
-- not in the third. Sharing is only ever for a shape that actually coincides.
--
-- `tally` is where the count of counters ACTUALLY removed is written, for a
-- later effect of the same resolution to read as Quantity.InSlot -- Ashling the
-- Pilgrim's "remove all +1/+1 counters from Ashling, and it deals THAT MUCH
-- damage". Parun.Types.Destroy's `slot` one opcode over, and absent for a removal
-- nothing looks back at, which is every removal in the pool but that one.
--
-- Needed rather than convenient: CR 608.2c carries the clause's instructions out
-- in printed order, so by the time the damage runs the counters are off and a
-- Quantity.ObjectCounters read would answer 0 -- and reordering the two is
-- observable, Ashling being 1/1 once its counters leave and dying to its own
-- damage.
data RemoveCounters = MkRemoveCounters
  { kind :: CounterKind.CounterKind Keyword.Keyword,
    quantity :: Quantity.Quantity,
    slot :: SlotName.SlotName,
    tally :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
