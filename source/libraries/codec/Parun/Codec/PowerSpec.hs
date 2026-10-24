module Parun.Codec.PowerSpec where

import qualified Parun.Codec.Power as Power
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Power as Power
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Power" $ do
  Spec.it s "MkPower delegates to Quantity" $
    Common.assertCodec
      s
      Power.codec
      (Power.MkPower (Quantity.Literal 2))
      " {\"type\":\"Literal\",\"value\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Power.codec
