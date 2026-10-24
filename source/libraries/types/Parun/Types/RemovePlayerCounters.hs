module Parun.Types.RemovePlayerCounters where

import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | CR 122: "these players lose this many of this kind" -- Parun.Types.Effect's
-- RemovePlayerCounters arm. Spun out of Parun.Types.PlayerCounters, which
-- GainPlayerCounters keeps, when the removal alone needed a tally.
data RemovePlayerCounters = MkRemovePlayerCounters
  { player :: PlayerRef.PlayerRef,
    kind :: PlayerCounterKind.PlayerCounterKind,
    quantity :: Quantity.Quantity,
    -- | Where to bind how many counters the player lost, for a later effect's
    -- "that much" (Leeches) -- Parun.Types.RemoveCounters' tally, on a player.
    tally :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
