module Pawl.Codec.NinjutsuVariantSpec where

import qualified Pawl.Codec.NinjutsuVariant as NinjutsuVariant
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.NinjutsuVariant as NinjutsuVariant

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.NinjutsuVariant" $ do
  Spec.it s "Commander" $
    Common.assertCodec
      s
      NinjutsuVariant.codec
      NinjutsuVariant.Commander
      " {\"type\":\"Commander\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s NinjutsuVariant.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s NinjutsuVariant.codec
