module Parun.Codec.TogetherSpec where

import qualified Parun.Codec.Together as Together
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Together as Together

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Together" $ do
  Spec.it s "InOneZone" $
    Common.assertCodec
      s
      Together.codec
      Together.InOneZone
      " {\"type\":\"InOneZone\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Together.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Together.codec
