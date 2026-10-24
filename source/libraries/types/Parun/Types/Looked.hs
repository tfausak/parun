module Parun.Types.Looked where

import Data.Set (Set)
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics

-- | CR 701.20e: a card was looked at, the card's characteristics as of the
-- look, and the players it was shown to -- the looker and, per CR 723.4, the
-- player controlling the looker.
data Looked = MkLooked
  { card :: ObjectId.ObjectId,
    characteristics :: ProjectedCharacteristics.ProjectedCharacteristics,
    audience :: Set PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
