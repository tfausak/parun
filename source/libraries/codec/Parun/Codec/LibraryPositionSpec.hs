module Parun.Codec.LibraryPositionSpec where

import qualified Parun.Codec.LibraryPosition as LibraryPosition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LibraryPosition as LibraryPosition

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LibraryPosition" $ do
  Spec.it s "Top" $
    Common.assertCodec
      s
      LibraryPosition.codec
      LibraryPosition.Top
      " {\"type\":\"Top\"} "
  Spec.it s "Bottom" $
    Common.assertCodec
      s
      LibraryPosition.codec
      LibraryPosition.Bottom
      " {\"type\":\"Bottom\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s LibraryPosition.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s LibraryPosition.codec
