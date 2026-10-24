module Parun.Types.DefendersAre where

import qualified Parun.Types.Label as Label

-- | CR 506.2: the defending players who may be attacked (Parun.Types.Combat's
-- defenders, not its CR 811.4 barred), in the order CR 802.4 has them declare.
newtype DefendersAre = MkDefendersAre
  { players :: [Label.Label]
  }
  deriving (Eq, Ord, Show)
