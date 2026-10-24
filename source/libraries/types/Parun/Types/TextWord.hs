module Parun.Types.TextWord where

import qualified Parun.Types.Color as Color
import qualified Parun.Types.Subtype as Subtype

-- | CR 612.2: a word a text-changing effect can replace, by the way it is used.
data TextWord
  = -- | CR 105.1's colour word used as a colour word.
    ColorWord Color.Color
  | -- | CR 205.3's subtype word used as a subtype.
    SubtypeWord Subtype.Subtype
  deriving (Eq, Ord, Show)
