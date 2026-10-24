module Parun.Codec.ManaTypeSpec where

import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaType" $ do
  Spec.it s "Colored" $
    Common.assertCodec
      s
      ManaType.codec
      (ManaType.Colored Color.Red)
      " {\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}} "
  Spec.it s "Colorless" $
    Common.assertCodec
      s
      ManaType.codec
      ManaType.Colorless
      " {\"type\":\"Colorless\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ManaType.codec
