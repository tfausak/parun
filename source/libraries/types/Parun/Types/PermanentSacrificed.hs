module Parun.Types.PermanentSacrificed where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 701.21a: which player's sacrifice fires the ability, and which quality
-- the permanent they sacrificed has to have -- Vengeful Tracker's "whenever an
-- opponent sacrifices an artifact".
--
-- A record for Parun.Types.PlayerAttacksWith's reason: the printed form pairs a
-- subject with a narrowing, and neither half has a default -- Mayhem Devil's
-- unrestricted "whenever a player sacrifices a permanent" spells both out as
-- AnyPlayer and the trivial Filter.
data PermanentSacrificed = MkPermanentSacrificed
  { player :: PlayerRelation.PlayerRelation,
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
