module Pawl.Types.Hotseat where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.PlayerId as PlayerId

-- | What the text client keeps between lines, for seats sharing one screen.
data Hotseat = MkHotseat
  { -- | The seat the screen last showed.
    facing :: Maybe PlayerId.PlayerId,
    -- | CR 104.3a: the seats that asked to concede.
    conceding :: Set.Set PlayerId.PlayerId,
    -- | Per seat, the turn and how many of its witnessed entries it was shown.
    shown :: Map.Map PlayerId.PlayerId (Natural.Natural, Natural.Natural),
    -- | Whether a priority offering only passing and mana abilities is passed
    -- without asking.
    autoPass :: Bool,
    -- | Each seat that typed "auto" during the payment now under way, beside
    -- the colors the source auto last tapped is for.
    paying :: Map.Map PlayerId.PlayerId (Set.Set ManaType.ManaType)
  }
  deriving (Eq, Show)

-- | A screen no seat has looked at yet, passing for a seat with nothing
-- else to do.
fresh :: Hotseat
fresh = MkHotseat {facing = Nothing, conceding = Set.empty, shown = Map.empty, autoPass = True, paying = Map.empty}
