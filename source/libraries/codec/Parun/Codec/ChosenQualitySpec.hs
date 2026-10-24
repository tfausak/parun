module Parun.Codec.ChosenQualitySpec where

import qualified Parun.Codec.ChosenQuality as ChosenQuality
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChosenQuality as ChosenQuality

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChosenQuality" $ do
  Spec.it s "Color" $
    Common.assertCodec
      s
      ChosenQuality.codec
      ChosenQuality.Color
      " {\"type\":\"Color\"} "
  Spec.it s "BasicLandType" $
    Common.assertCodec
      s
      ChosenQuality.codec
      ChosenQuality.BasicLandType
      " {\"type\":\"BasicLandType\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ChosenQuality.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ChosenQuality.codec
