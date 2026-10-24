module Parun.Codec.GraveyardOrderSpec where

import qualified Parun.Codec.GraveyardOrder as GraveyardOrder
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.GraveyardOrder as GraveyardOrder.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.GraveyardOrder" $ do
  Spec.it s "Matters" $
    Common.assertCodec s GraveyardOrder.codec GraveyardOrder.Type.Matters " {\"type\":\"Matters\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s GraveyardOrder.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s GraveyardOrder.codec
