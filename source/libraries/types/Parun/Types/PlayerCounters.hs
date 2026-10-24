module Parun.Types.PlayerCounters where

import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity

-- | CR 122: "these players, this kind, this many" -- the payload of
-- Parun.Types.Effect's GainPlayerCounters arm (#1305). RemovePlayerCounters
-- shared it until the removal alone needed a tally, and has its own
-- (Parun.Types.RemovePlayerCounters); the two are separate CONSTRUCTORS for the
-- reason LoseLife and GainLife are.
data PlayerCounters = MkPlayerCounters
  { player :: PlayerRef.PlayerRef,
    kind :: PlayerCounterKind.PlayerCounterKind,
    quantity :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
