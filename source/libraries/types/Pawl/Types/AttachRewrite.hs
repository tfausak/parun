module Pawl.Types.AttachRewrite where

import Numeric.Natural (Natural)
import qualified Pawl.Types.AsCopy as AsCopy

-- | What an "as this becomes attached to a creature" ability does as the
-- permanent becomes attached (CR 701.3a).
data AttachRewrite ability effect
  = -- | CR 707.2c / 611.3a: choose an object, and what the permanent is
    -- attached to is a copy of the last one chosen (Dinosaur Headdress).
    AsCopy (AsCopy.AsCopy ability effect)
  | -- | CR 105.4 / 607.2d: choose that many colours, replacing the last
    -- choice (Sanctuary Blade). EntryRewrite.ChooseColors' payload.
    ChooseColors Natural
  deriving (Eq, Ord, Show)
