module Parun.Types.Ninjutsu where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.NinjutsuVariant as NinjutsuVariant

-- | The payload of Parun.Types.Keyword's Ninjutsu arm: CR 702.49a's "Ninjutsu
-- [cost]", and CR 702.49d's commander ninjutsu as one field on it.
--
-- PARAMETRIC in the keyword for Parun.Types.Cycling's reason: the Cost can name a
-- Keyword and Keyword names this. Only @Ninjutsu Keyword.Keyword@ is ever
-- written.
data Ninjutsu keyword = MkNinjutsu
  { cost :: Cost.Cost keyword,
    variant :: NinjutsuVariant.NinjutsuVariant
  }
  deriving (Eq, Ord, Show)
