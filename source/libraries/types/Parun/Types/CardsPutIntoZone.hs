module Parun.Types.CardsPutIntoZone where

import qualified Data.Set as Set
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | Which arriving cards fire a "whenever one or more cards are put into [a
-- zone]" ability (CR 603.2c), and from where -- Dutiful Knowledge Seeker's "into
-- a library from anywhere".
--
-- The arrival-side twin of Parun.Types.CardLeavesZone: the zone the card reached
-- is fixed and the zone it left may be any. The Filter is read against each
-- arriving object (CR 730.3's components one by one); the zones are no
-- characteristic of the card, so they come from the event.
data CardsPutIntoZone = MkCardsPutIntoZone
  { filter :: Filter.Filter Keyword.Keyword,
    -- | Whose turns it fires on: Stonebinder's Familiar's "during your turn".
    scope :: TurnScope.TurnScope,
    -- | The zones it may have come from (CR 400.7); empty admits any.
    from :: Set.Set Zone.Zone,
    -- | The zone it was put into.
    to :: Zone.Zone
  }
  deriving (Eq, Ord, Show)
