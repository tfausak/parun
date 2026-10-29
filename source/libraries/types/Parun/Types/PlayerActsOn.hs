module Parun.Types.PlayerActsOn where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 603.2: which player's act fires the ability, and which quality the
-- object the act names has to have -- Vengeful Tracker's "whenever an opponent
-- sacrifices an artifact" (CR 701.21a), Waste Not's "whenever an opponent
-- discards a creature card" (CR 701.9a).
--
-- A record for Parun.Types.PlayerAttacksWith's reason: the printed form pairs a
-- subject with a narrowing, and neither half has a default -- Mayhem Devil's
-- unrestricted "whenever a player sacrifices a permanent" spells both out as
-- AnyPlayer and the trivial Filter.
data PlayerActsOn = MkPlayerActsOn
  { player :: PlayerRelation.PlayerRelation,
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
