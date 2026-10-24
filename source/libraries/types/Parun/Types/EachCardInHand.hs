module Parun.Types.EachCardInHand where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ZoneScope as ZoneScope

-- | CR 400.1: every card in the named players' hands that matches -- Amnesia's
-- "target player reveals their hand and discards all nonland cards".
--
-- Parun.Types.EachCardInGraveyard's shape over the other per-player zone, and
-- resolved the same way: the same scope, read by the same
-- Parun.Engine.Target.zoneScopePlayers, and the same fold in
-- Parun.Engine.Resolve.Slots.objectRefObjects. The zone is BAKED IN rather than carried
-- as a Parun.Types.Zone, for the reason that arm's header gives.
--
-- THE HIDDEN-ZONE QUESTION (CR 400.2) IS THE CARD'S TO ANSWER, NOT THE ENGINE'S.
-- Parun.Types.ObjectRef.EachCardInYourHand avoids it by reaching only the
-- resolving controller's own hand; this arm reaches anyone's, so which cards
-- matched is read off what left the zone. parun models CR 400.2 as a rules
-- property -- which pools and slots may name a hidden zone -- rather than as
-- information hiding in Parun.Types.GameState, so what makes this arm legitimate
-- is that its producer PRINTS the reveal (CR 701.20a) that shows the hand first,
-- or the look (CR 701.20e) that shows it to the card's controller (The Raven's
-- Warning). A card sweeping a hand it neither reveals nor looks at would leak,
-- and none is written.
--
-- The Filter is OPTIONAL, Parun.Types.EachCardInExiledPile's
-- reason: Parun.Types.Filter has no tautological arm, so "reveals their hand" --
-- the whole of it, which is Amnesia's first instruction -- has no other spelling.
--
-- Not a target and never one (CR 115.10a), so CR 608.2b has nothing to fizzle,
-- and swept when the effect executes (CR 608.2c) -- the two properties every
-- sweeping arm has.
data EachCardInHand = MkEachCardInHand
  { hands :: ZoneScope.ZoneScope,
    filter :: Maybe (Filter.Filter Keyword.Keyword)
  }
  deriving (Eq, Ord, Show)
