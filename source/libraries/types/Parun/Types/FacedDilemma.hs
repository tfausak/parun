module Parun.Types.FacedDilemma where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 700.17: a player faced a dilemma -- who chose the modes (CR 700.2e's
-- chooser, not necessarily the controller) and the spell or ability on the
-- stack they chose them for.
data FacedDilemma = MkFacedDilemma
  { player :: PlayerId.PlayerId,
    object :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
