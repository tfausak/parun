module Parun.Types.Craft where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ExileMaterials as ExileMaterials

-- | The payload of Parun.Types.Keyword's Craft arm: CR 702.167a's "Craft with
-- [materials] [cost]".
--
-- PARAMETRIC in the keyword, for Parun.Types.Equip's reason: the fields name a
-- Cost and an ExileMaterials, both of which can name a Keyword, and Keyword
-- names THIS. Only @Craft Keyword.Keyword@ is ever written.
--
-- The two fields are the two blanks rule 702.167a leaves: what is paid, and what
-- is exiled. Everything else in the rule's sentence -- exiling this permanent,
-- the return transformed under its owner's control, the sorcery-speed rider --
-- is fixed for every printing and lives in Parun.Engine.Keyword.craft.
data Craft keyword = MkCraft
  { cost :: Cost.Cost keyword,
    materials :: ExileMaterials.ExileMaterials keyword
  }
  deriving (Eq, Ord, Show)
