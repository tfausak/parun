module Parun.Types.Grouping where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Types.SlotName as SlotName

-- | The groups an Effect.ChooseGroup chooses one of.
data Grouping
  = -- | CR 702.158d: the three sector designations.
    Sectors
  | -- | CR 700.3: the piles an earlier instruction of this resolution bound
    -- under these slots, in order (Raging River's "left" and "right").
    Piles (NonEmpty.NonEmpty SlotName.SlotName)
  deriving (Eq, Ord, Show)
