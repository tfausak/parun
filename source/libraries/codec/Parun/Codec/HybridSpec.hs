module Parun.Codec.HybridSpec where

import qualified Parun.Codec.Hybrid as Hybrid
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Hybrid" $ do
  -- CR 107.4e. BOTH keys are a ManaType, so the fixture names them differently
  -- on purpose: only an asymmetric case catches a codec that swapped the halves.
  Spec.it s "MkHybrid, both keys" $
    Common.assertCodec
      s
      Hybrid.codec
      (Hybrid.MkHybrid {Hybrid.left = ManaType.Colored Color.White, Hybrid.right = ManaType.Colored Color.Blue})
      " {\"left\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}},\"right\":{\"type\":\"Colored\",\"value\":{\"type\":\"Blue\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Hybrid.codec
