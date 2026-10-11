module Pawl.Types.ExileFromGraveyard where

import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.PlayerScope as PlayerScope

-- | CR 614.1c / 614.13's as-enters exile out of a graveyard: what may be
-- exiled, out of whose graveyards, and how many.
--
-- A PlayerScope rather than Pawl.Types.ZoneScope, whose slot arms an entry
-- replacement cannot answer: no resolution binds a slot as a permanent enters.
data ExileFromGraveyard = MkExileFromGraveyard
  { filter :: Filter.Filter Keyword.Keyword,
    -- | CR 109.5 against the entering permanent's controller: Living Lore's
    -- "your graveyard", Dermotaxi's "a graveyard".
    players :: PlayerScope.PlayerScope,
    -- | Living Lore's "an instant or sorcery card" is one; Sutured Ghoul's "any
    -- number" is UpTo with no ceiling.
    count :: HowMany.HowMany
  }
  deriving (Eq, Ord, Show)
