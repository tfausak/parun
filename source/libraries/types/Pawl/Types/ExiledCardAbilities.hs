module Pawl.Types.ExiledCardAbilities where

import qualified Pawl.Types.ActivationRestriction as ActivationRestriction
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | The payload of Pawl.Types.Modification's GainExiledCardAbilities arm: which
-- cards in exile lend the object their activated abilities, and the
-- restrictions each of them gains.
data ExiledCardAbilities = MkExiledCardAbilities
  { -- | Matched against each card in exile, framed by the effect's source: a
    -- pile linked to it (Filter.IsExiledWithSource, Myr Welder) or any other
    -- quality of the card (Mairsil, the Pretender's "cards you own in exile
    -- with cage counters on them").
    cards :: Filter.Filter Keyword.Keyword,
    restrictions :: [ActivationRestriction.ActivationRestriction]
  }
  deriving (Eq, Ord, Show)
