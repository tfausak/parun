module Parun.Codec.LibraryDepartureSpec where

import qualified Parun.Codec.LibraryDeparture as LibraryDeparture
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LibraryDeparture as LibraryDeparture

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LibraryDeparture" $ do
  Spec.it s "Milled" $
    Common.assertCodec
      s
      LibraryDeparture.codec
      LibraryDeparture.Milled
      " \"Milled\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s LibraryDeparture.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s LibraryDeparture.codec
