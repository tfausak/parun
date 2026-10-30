module Parun.Codec.CounterabilitySpec where

import qualified Parun.Codec.Counterability as Counterability
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Counterability as Counterability

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Counterability" $ do
  Spec.it s "Counterable" $
    Common.assertCodec
      s
      Counterability.codec
      Counterability.Counterable
      " {\"type\":\"Counterable\"} "
  Spec.it s "CantBeCountered" $
    Common.assertCodec
      s
      Counterability.codec
      (Counterability.CantBeCountered Nothing)
      " {\"type\":\"CantBeCountered\"} "
  Spec.it s "CantBeCountered, conditionally" $
    Common.assertCodec
      s
      Counterability.codec
      (Counterability.CantBeCountered (Just (Condition.Any [])))
      " {\"type\":\"CantBeCountered\",\"value\":{\"type\":\"Any\",\"value\":[]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Counterability.codec
