module Pawl.Types.Hotseat where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.PlayerId as PlayerId

-- | What the text client keeps between lines, for seats sharing one screen.
data Hotseat = MkHotseat
  { -- | The seat the screen last showed.
    facing :: Maybe PlayerId.PlayerId,
    -- | CR 104.3a: the seats that asked to concede.
    conceding :: Set.Set PlayerId.PlayerId,
    -- | Per seat, the turn and how many of its witnessed entries it was shown.
    shown :: Map.Map PlayerId.PlayerId (Natural.Natural, Natural.Natural)
  }
  deriving (Eq, Show)

-- | A screen no seat has looked at yet.
fresh :: Hotseat
fresh = MkHotseat {facing = Nothing, conceding = Set.empty, shown = Map.empty}
