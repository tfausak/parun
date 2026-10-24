module Parun.Types.EachCardInGraveyard where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ZoneScope as ZoneScope

-- | CR 404.1: every card in the named players' graveyards that matches.
--
-- A Parun.Types.ZoneScope and not the Parun.Types.PlayerScope this used to
-- carry, so the sweep can say Angel of Finality's "target player's graveyard" --
-- the players another slot of the same announcement holds. CR 400.1's per-player
-- zone leaves a sweep the same two readings a target pool has
-- (Parun.Types.Pool.CardsInGraveyard), and both are answerable HERE because a
-- sweep resolves: Parun.Engine.Resolve reads the InSlot arm off the bindings CR
-- 608.2b left legal, exactly as Parun.Engine.Target reads it off the ones CR
-- 601.2c is choosing among.
data EachCardInGraveyard = MkEachCardInGraveyard
  { graveyards :: ZoneScope.ZoneScope,
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
