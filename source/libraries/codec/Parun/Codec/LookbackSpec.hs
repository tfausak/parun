module Parun.Codec.LookbackSpec where

import qualified Parun.Codec.Lookback as Lookback
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Lookback as Lookback

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Lookback" $ do
  Spec.it s "ThisTurn" $
    Common.assertCodec
      s
      Lookback.codec
      Lookback.ThisTurn
      " {\"type\":\"ThisTurn\"} "
  Spec.it s "AsThisObject" $
    Common.assertCodec
      s
      Lookback.codec
      Lookback.AsThisObject
      " {\"type\":\"AsThisObject\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Lookback.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Lookback.codec
