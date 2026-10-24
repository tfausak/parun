module Parun.Codec.CoinReadingSpec where

import qualified Parun.Codec.CoinReading as CoinReading
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CoinReading as CoinReading

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CoinReading" $ do
  Spec.it s "Wins" $
    Common.assertCodec
      s
      CoinReading.codec
      CoinReading.Wins
      " {\"type\":\"Wins\"} "
  Spec.it s "Heads" $
    Common.assertCodec
      s
      CoinReading.codec
      CoinReading.Heads
      " {\"type\":\"Heads\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CoinReading.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CoinReading.codec
