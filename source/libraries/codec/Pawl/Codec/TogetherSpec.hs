module Pawl.Codec.TogetherSpec where

import qualified Pawl.Codec.Together as Together
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Together as Together

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Together" $ do
  Spec.it s "InOneZone" $
    Common.assertCodec
      s
      Together.codec
      Together.InOneZone
      " {\"type\":\"InOneZone\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Together.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Together.codec
