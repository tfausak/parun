module Parun.Codec.PlanarDieFaceSpec where

import qualified Parun.Codec.PlanarDieFace as PlanarDieFace
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlanarDieFace as PlanarDieFace

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlanarDieFace" $ do
  Spec.it s "Chaos" $
    Common.assertCodec
      s
      PlanarDieFace.codec
      PlanarDieFace.Chaos
      " {\"type\":\"Chaos\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PlanarDieFace.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlanarDieFace.codec
