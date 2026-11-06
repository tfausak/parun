module Parun.Codec.ColorSpreadSpec where

import qualified Parun.Codec.ColorSpread as ColorSpread
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ColorSpread as ColorSpread

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ColorSpread" $ do
  Spec.it s "AnyCombination" $
    Common.assertCodec
      s
      ColorSpread.codec
      ColorSpread.AnyCombination
      " \"AnyCombination\" "

  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ColorSpread.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ColorSpread.codec
