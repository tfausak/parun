module Parun.Codec.DamageDealerSpec where

import qualified Parun.Codec.DamageDealer as DamageDealer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageDealer as DamageDealer

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageDealer" $ do
  Spec.it s "Source" $
    Common.assertCodec
      s
      DamageDealer.codec
      DamageDealer.Source
      " {\"type\":\"Source\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DamageDealer.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s DamageDealer.codec
