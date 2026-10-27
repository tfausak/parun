module Parun.Types.ManaR where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaType as ManaType

-- | The payload of Parun.Types.ReplacementEffect's ManaR arm: CR 106.12b's
-- permanent "tapped for mana", and the type it produces "instead of any other
-- type" (Naked Singularity's "Plains produce {R}"). The amount is kept, which
-- Ritual of Subdual's ruling states.
--
-- Not implemented: Contamination's "instead of any other type and amount"
-- (#5663).
data ManaR = MkManaR
  { matching :: Filter.Filter Keyword.Keyword,
    produces :: ManaType.ManaType
  }
  deriving (Eq, Ord, Show)
