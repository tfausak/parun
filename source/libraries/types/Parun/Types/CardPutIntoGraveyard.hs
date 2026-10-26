module Parun.Types.CardPutIntoGraveyard where

import qualified Data.Set as Set
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Zone as Zone

-- | Which arriving cards fire a bystander's "whenever a card is put into a
-- graveyard" ability (CR 603.6), and from where -- Planar Void's "from
-- anywhere", Oglor, Devoted Assistant's "from your library or hand".
--
-- The Filter is read against the arriving card, so "your graveyard" is a
-- Filter.HeldBy Holder.Owner conjunct (CR 400.3). The zones it left are no characteristic
-- of the card, so they come from the event.
data CardPutIntoGraveyard = MkCardPutIntoGraveyard
  { filter :: Filter.Filter Keyword.Keyword,
    -- | The zones it may have come from (CR 400.7); empty admits any.
    from :: Set.Set Zone.Zone
  }
  deriving (Eq, Ord, Show)
