module Parun.Types.AttachRewrite where

import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.ChosenQuality as ChosenQuality

-- | What an "as this becomes attached to a creature" ability does as the
-- permanent becomes attached (CR 701.3a).
data AttachRewrite ability effect
  = -- | CR 707.2c / 611.3a: choose an object, and what the permanent is
    -- attached to is a copy of the last one chosen (Dinosaur Headdress).
    AsCopy (AsCopy.AsCopy ability effect)
  | -- | CR 607.2d: choose this quality, replacing the last choice (Sanctuary Blade).
    ChooseQuality ChosenQuality.ChosenQuality
  deriving (Eq, Ord, Show)
