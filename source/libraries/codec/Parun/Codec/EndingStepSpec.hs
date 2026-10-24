module Parun.Codec.EndingStepSpec where

import qualified Parun.Codec.EndingStep as EndingStep
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EndingStep as EndingStep

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EndingStep" $ do
  Spec.it s "EndStep" $
    Common.assertCodec
      s
      EndingStep.codec
      EndingStep.EndStep
      " {\"type\":\"EndStep\"} "
  Spec.it s "Cleanup" $
    Common.assertCodec
      s
      EndingStep.codec
      EndingStep.Cleanup
      " {\"type\":\"Cleanup\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s EndingStep.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s EndingStep.codec
