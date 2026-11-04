module Parun.Codec.BatchingSpec where

import qualified Parun.Codec.Batching as Batching
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Batching as Batching

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Batching" $ do
  Spec.it s "OneOrMore" $
    Common.assertCodec
      s
      Batching.codec
      Batching.OneOrMore
      " {\"type\":\"OneOrMore\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Batching.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Batching.codec
