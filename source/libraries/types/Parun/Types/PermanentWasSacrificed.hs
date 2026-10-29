module Parun.Types.PermanentWasSacrificed where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 701.21a: a permanent was sacrificed, and by whom.

-- Named for the event rather than for the constructor, since
-- Parun.Types.PlayerActsOn is already the TRIGGER CONDITION's payload --
-- Parun.Types.SpellWasCast's reason, and the same pair of ends: that one says
-- which sacrifices an ability watches for, this one says which one happened.
data PermanentWasSacrificed = MkPermanentWasSacrificed
  { player :: PlayerId.PlayerId,
    permanent :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
