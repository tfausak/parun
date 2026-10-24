module Parun.Types.ExiledCardAbilities where

import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.Modification's GainExiledCardAbilities arm: which
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
