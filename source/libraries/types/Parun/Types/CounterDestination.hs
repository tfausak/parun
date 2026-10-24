module Parun.Types.CounterDestination where

import qualified Parun.Types.CounteredEnd as CounteredEnd
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Zone as Zone

-- | Where a countered spell goes instead of CR 701.6a's graveyard: Delay's
-- exile, Remand's hand, Memory Lapse's library top, Hinder's library end of
-- its controller's choice, Desertion's battlefield.
--
-- `only` narrows which countered spells it applies to -- Desertion's "if an
-- artifact or creature spell is countered this way" -- and is read off the
-- spell on the stack; absent, it applies to every countered spell.
--
-- `slot` binds the cards the countering put into `zone`, as a group, for a
-- later effect of the same resolution to name -- Delay's "exile it with three
-- time counters on it".
data CounterDestination = MkCounterDestination
  { zone :: Zone.Zone,
    position :: CounteredEnd.CounteredEnd,
    only :: Maybe (Filter.Filter Keyword.Keyword),
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
