module Parun.Codec.HopSpec where

import qualified Parun.Codec.Hop as Hop
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Hop as Hop

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Hop" $ do
  Spec.it s "Host" $
    Common.assertCodec
      s
      Hop.codec
      Hop.Host
      " {\"type\":\"Host\"} "
  -- Parun.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Hop.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Hop.codec
