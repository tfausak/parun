module Parun.Codec.LandAllowanceSpec where

import qualified Parun.Codec.LandAllowance as LandAllowance
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LandAllowance as LandAllowance

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LandAllowance" $ do
  Spec.it s "Additional" $
    Common.assertCodec
      s
      LandAllowance.codec
      (LandAllowance.Additional 2)
      " {\"type\":\"Additional\",\"value\":2} "
  Spec.it s "AnyNumber" $
    Common.assertCodec
      s
      LandAllowance.codec
      LandAllowance.AnyNumber
      " {\"type\":\"AnyNumber\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s LandAllowance.codec
