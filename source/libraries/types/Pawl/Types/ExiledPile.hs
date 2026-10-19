module Pawl.Types.ExiledPile where

import qualified Pawl.Types.AbilityName as AbilityName

-- | CR 607.2a: which of the cards in exile linked to a source a reader means,
-- as Pawl.Engine.Binding.isLinkedExile answers it.
data ExiledPile
  = -- | CR 607.2a / 607.4: every card an ability the source has of its own
    -- exiled (Steward of the Harvest, Sutured Ghoul, Patchwork Crawler).
    OwnAbilities
  | -- | CR 607.2a: every card the named ability of the source exiled (Synthetic
    -- Split Reliquary).
    OfAbility AbilityName.AbilityName
  | -- | CR 607.2b / 614.14: every card the source's as-enters exile took
    -- (Mimeoplasm, Revered One).
    AsItEntered
  | -- | CR 702.167c: the cards exiled to craft the source (Locus of
    -- Enlightenment).
    CraftMaterials
  deriving (Eq, Ord, Show)
