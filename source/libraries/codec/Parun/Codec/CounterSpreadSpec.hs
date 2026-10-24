module Parun.Codec.CounterSpreadSpec where

import qualified Parun.Codec.CounterSpread as CounterSpread
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterSpread as CounterSpread

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterSpread" $ do
  Spec.it s "FromOne" $
    Common.assertCodec
      s
      CounterSpread.codec
      CounterSpread.FromOne
      " {\"type\":\"FromOne\"} "

  Spec.it s "FromAmong" $
    Common.assertCodec
      s
      CounterSpread.codec
      CounterSpread.FromAmong
      " {\"type\":\"FromAmong\"} "

  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CounterSpread.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterSpread.codec
