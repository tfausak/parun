module Parun.Codec.ScalingSpec where

import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Scaling" $ do
  Spec.it s "Multiply" $
    Common.assertCodec
      s
      Scaling.codec
      (Scaling.Multiply 2)
      " {\"type\":\"Multiply\",\"value\":2} "
  Spec.it s "AddMore" $
    Common.assertCodec
      s
      Scaling.codec
      (Scaling.AddMore 1)
      " {\"type\":\"AddMore\",\"value\":1} "
  Spec.it s "Subtract" $
    Common.assertCodec
      s
      Scaling.codec
      (Scaling.Subtract 1)
      " {\"type\":\"Subtract\",\"value\":1} "
  Spec.it s "Halve" $
    Common.assertCodec
      s
      Scaling.codec
      Scaling.Halve
      " {\"type\":\"Halve\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Scaling.codec
