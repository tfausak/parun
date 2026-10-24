module Parun.Codec.RevealTimingSpec where

import qualified Parun.Codec.RevealTiming as RevealTiming
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.RevealTiming as RevealTiming

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RevealTiming" $ do
  Spec.it s "OnceCast" $
    Common.assertCodec
      s
      RevealTiming.codec
      RevealTiming.OnceCast
      " {\"type\":\"OnceCast\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s RevealTiming.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s RevealTiming.codec
