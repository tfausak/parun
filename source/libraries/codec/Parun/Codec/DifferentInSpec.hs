module Parun.Codec.DifferentInSpec where

import qualified Parun.Codec.DifferentIn as DifferentIn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DifferentIn as DifferentIn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DifferentIn" $ do
  Spec.it s "Powers" $
    Common.assertCodec
      s
      DifferentIn.codec
      DifferentIn.Powers
      " {\"type\":\"Powers\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DifferentIn.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s DifferentIn.codec
