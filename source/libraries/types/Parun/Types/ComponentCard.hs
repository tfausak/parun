module Parun.Types.ComponentCard where

import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics

-- | CR 108.2 / 731.2 / 701.42a: one card representing a merged or melded
-- permanent -- the card-level facts Parun.Types.Object keeps across CR 400.7,
-- which CR 713.8's and CR 731.3's split hands back to that card alone.
data ComponentCard = MkComponentCard
  { printing :: PrintingId.PrintingId,
    -- | CR 108.3: Object.identity of the card, Nothing where the object had none.
    identity :: Maybe CardIdentity.CardIdentity,
    -- | CR 707.2: a conjured duplicate's copiable values (Object.duplicate).
    duplicate :: Maybe ProjectedCharacteristics.ProjectedCharacteristics
  }
  deriving (Eq, Ord, Show)
