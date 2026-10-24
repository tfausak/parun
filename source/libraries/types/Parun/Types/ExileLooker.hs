module Parun.Types.ExileLooker where

import qualified Parun.Types.PlayerId as PlayerId

-- | CR 406.3: one grant of permission to look at a card exiled face down. A set
-- of these is 'Parun.Types.Object.exileLookers', and
-- 'Parun.Engine.Exile.mayLookAt' is what asks each of them about a player. Ord
-- because it is a Set member.
data ExileLooker
  = -- | CR 406.3: the seat the instruction named, stored (Extract Power).
    ThePlayer PlayerId.PlayerId
  | -- | CR 702.75a: whoever controls the permanent that exiled the card, asked
    -- afresh each time (Windbrisk Heights). It carries no object, CR 607.2's
    -- link ('Parun.Types.GameState.exiledWith') already naming that permanent.
    --
    -- CR 406.3 keeps the look a seat once had, which
    -- 'Parun.Engine.Exile.accrueLookers' records by stamping each such controller
    -- as a 'ThePlayer' beside this one.
    TheExiler
  deriving (Eq, Ord, Show)
