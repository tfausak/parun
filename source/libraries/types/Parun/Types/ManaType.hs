module Parun.Types.ManaType where

import qualified Parun.Types.Color as Color

-- | CR 106.1a/106.1b: mana is either one of the five colors or colorless.
data ManaType
  = Colored Color.Color
  | Colorless
  deriving (Eq, Ord, Show)
