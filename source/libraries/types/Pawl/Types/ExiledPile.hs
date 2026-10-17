module Pawl.Types.ExiledPile where

-- | CR 607.2a: which of the cards in exile linked to a source an effect reads.
data ExiledPile
  = -- | CR 702.167c: the cards exiled to craft the source (Locus of
    -- Enlightenment).
    CraftMaterials
  | -- | CR 607.2a: every card an ability the source has of its own exiled
    -- (Steward of the Harvest, Patchwork Crawler).
    ExiledWithSource
  deriving (Bounded, Enum, Eq, Ord, Show)
