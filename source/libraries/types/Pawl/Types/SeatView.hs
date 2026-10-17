module Pawl.Types.SeatView where

import qualified Data.Map.Strict as Map
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.Mana as Mana
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.PlayerCounterKind as PlayerCounterKind
import qualified Pawl.Types.PlayerId as PlayerId

-- | CR 400.2: one player's zones and totals as one seat sees them, a hidden
-- zone by its size and only the members that seat may see.
data SeatView = MkSeatView
  { player :: PlayerId.PlayerId,
    life :: Integer,
    counters :: Map.Map PlayerCounterKind.PlayerCounterKind Natural.Natural,
    handSize :: Natural.Natural,
    hand :: [ObjectView.ObjectView],
    librarySize :: Natural.Natural,
    library :: [ObjectView.ObjectView],
    graveyard :: [ObjectView.ObjectView],
    exile :: [ObjectView.ObjectView],
    manaPool :: Mana.Mana
  }
  deriving (Eq, Show)
