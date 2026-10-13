module Pawl.Codec.LandAllowanceSpec where

import qualified Pawl.Codec.LandAllowance as LandAllowance
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.LandAllowance as LandAllowance

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.LandAllowance" $ do
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
