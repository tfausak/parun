module Parun.Types.EntriesTrigger where

import qualified Parun.Types.EntryTriggering as EntryTriggering
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | A rule over the abilities a permanent entering causes to trigger, read for
-- the player whose abilities they are (Parun.Types.PlayerEffect.EntriesTrigger).
data EntriesTrigger = MkEntriesTrigger
  { -- | Which entrants it applies to, read as each exists on the battlefield.
    entrants :: Filter.Filter Keyword.Keyword,
    triggering :: EntryTriggering.EntryTriggering
  }
  deriving (Eq, Ord, Show)
