module Parun.Codec.DiscardWaySpec where

import qualified Parun.Codec.DiscardWay as DiscardWay
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DiscardWay as DiscardWay

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DiscardWay" $ do
  Spec.it s "Cycled" $
    Common.assertCodec
      s
      DiscardWay.codec
      DiscardWay.Cycled
      " {\"type\":\"Cycled\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DiscardWay.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s DiscardWay.codec
