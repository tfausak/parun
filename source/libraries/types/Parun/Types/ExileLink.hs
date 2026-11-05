module Parun.Types.ExileLink where

import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 607.2a: what an exiled card is linked to -- the object whose ability
-- exiled it, and that ability's name when it has one, so a reference naming one
-- of two exiling abilities reads only its own pile.
--
-- Nothing where the exiling ability is unnamed. CR 614.14's as-enters exile
-- carries the reserved Parun.Engine.Binding.entryExileLink, and CR 702.167c's
-- craft materials Parun.Engine.Binding.craftLink.
data ExileLink = MkExileLink
  { source :: ObjectId.ObjectId,
    ability :: Maybe AbilityName.AbilityName,
    -- | CR 607.5: the acquisition of the source's abilities the exiling ability
    -- came with, since only that acquisition's abilities refer to the card.
    acquisition :: Acquisition.Acquisition
  }
  deriving (Eq, Ord, Show)
