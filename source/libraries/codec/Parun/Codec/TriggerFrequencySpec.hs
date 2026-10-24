module Parun.Codec.TriggerFrequencySpec where

import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggerFrequency" $ do
  Spec.it s "EveryTime" $
    Common.assertCodec
      s
      TriggerFrequency.codec
      TriggerFrequency.EveryTime
      " {\"type\":\"EveryTime\"} "
  Spec.it s "FirstTimeEachTurn" $
    Common.assertCodec
      s
      TriggerFrequency.codec
      TriggerFrequency.FirstTimeEachTurn
      " {\"type\":\"FirstTimeEachTurn\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s TriggerFrequency.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s TriggerFrequency.codec
