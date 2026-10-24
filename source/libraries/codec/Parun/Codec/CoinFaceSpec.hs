module Parun.Codec.CoinFaceSpec where

import qualified Parun.Codec.CoinFace as CoinFace
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CoinFace as CoinFace

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CoinFace" $ do
  Spec.it s "Heads" $
    Common.assertCodec
      s
      CoinFace.codec
      CoinFace.Heads
      " {\"type\":\"Heads\"} "
  Spec.it s "Tails" $
    Common.assertCodec
      s
      CoinFace.codec
      CoinFace.Tails
      " {\"type\":\"Tails\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CoinFace.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CoinFace.codec
