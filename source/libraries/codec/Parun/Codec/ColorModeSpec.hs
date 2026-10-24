module Parun.Codec.ColorModeSpec where

import qualified Parun.Codec.ColorMode as ColorMode
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ColorMode as ColorMode

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ColorMode" $ do
  Spec.it s "Replace" $
    Common.assertCodec
      s
      ColorMode.codec
      ColorMode.Replace
      " {\"type\":\"Replace\"} "
  Spec.it s "InAddition" $
    Common.assertCodec
      s
      ColorMode.codec
      ColorMode.InAddition
      " {\"type\":\"InAddition\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ColorMode.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ColorMode.codec
