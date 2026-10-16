module Pawl.Types.ExiledCardAbilities where

import qualified Pawl.Types.ActivationRestriction as ActivationRestriction
import qualified Pawl.Types.ExiledPile as ExiledPile

-- | The payload of Pawl.Types.Modification's GainExiledCardAbilities arm: which
-- exiled cards' activated abilities the object has, and the restrictions each
-- of them gains.
data ExiledCardAbilities = MkExiledCardAbilities
  { pile :: ExiledPile.ExiledPile,
    restrictions :: [ActivationRestriction.ActivationRestriction]
  }
  deriving (Eq, Ord, Show)
