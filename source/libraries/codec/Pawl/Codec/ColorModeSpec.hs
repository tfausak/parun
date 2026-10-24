module Pawl.Codec.ColorModeSpec where

import qualified Pawl.Codec.ColorMode as ColorMode
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ColorMode as ColorMode

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ColorMode" $ do
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
