module Parun.Codec.ReadinessSpec where

import qualified Parun.Codec.Readiness as Readiness
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Readiness as Readiness.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Readiness" $ do
  Spec.it s "ready is true" $
    Common.assertCodec s Readiness.codec Readiness.Type.Ready " true "
  Spec.it s "sick is false" $
    Common.assertCodec s Readiness.codec Readiness.Type.Sick " false "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Readiness.codec
