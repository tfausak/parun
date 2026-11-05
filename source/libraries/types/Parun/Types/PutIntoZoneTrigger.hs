module Parun.Types.PutIntoZoneTrigger where

import qualified Data.Set as Set
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | CR 603.6: a card put into a zone other than the battlefield -- which card,
-- from where, on whose turns, and per card or per batch (CR 603.2c).
-- Narcomoeba's "put into your graveyard from your library", Planar Void's
-- "another card is put into a graveyard from anywhere", Dutiful Knowledge
-- Seeker's "one or more cards are put into a library from anywhere".
--
-- A Matching card's Filter reads each ARRIVAL (CR 730.3's components one by
-- one); the zones are no characteristic of the card and come from the event.
data PutIntoZoneTrigger = MkPutIntoZoneTrigger
  { card :: ActingPermanent.ActingPermanent,
    -- | The zones it may have come from (CR 400.7); empty admits any.
    from :: Set.Set Zone.Zone,
    -- | The zone it was put into.
    to :: Zone.Zone,
    scope :: TurnScope.TurnScope,
    -- | CR 608.2n: admit only a spell's move as the last step of its own
    -- resolution (CR 702.55a's "put into a graveyard during its resolution").
    duringResolution :: Bool,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)

-- | "When this card is put into [a zone] from anywhere": the source, each turn,
-- once per move. The codec's defaults but the required destination.
self :: Zone.Zone -> PutIntoZoneTrigger
self zone =
  MkPutIntoZoneTrigger
    { card = ActingPermanent.Self,
      from = Set.empty,
      to = zone,
      scope = TurnScope.EachTurn,
      duringResolution = False,
      batching = Batching.EachOccurrence
    }
