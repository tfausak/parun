module Parun.Types.Dividing where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Numeric.Natural as Natural

-- | What Parun.Types.Prompt's ChooseDivision asks a player to hand out among
-- the targets it names, each target taking at least one.
data Dividing
  = -- | CR 601.2d: any division of this total, announced as the spell is cast.
    Total Natural.Natural
  | -- | CR 115.7f: exactly these parts, ascending, one to each new target --
    -- the parts the replaced targets held, which a change of targets keeps.
    Parts (NonEmpty.NonEmpty Natural.Natural)
  deriving (Eq, Ord, Show)

-- | The total handed out.
total :: Dividing -> Natural.Natural
total dividing = case dividing of
  Total n -> n
  Parts parts -> sum parts
