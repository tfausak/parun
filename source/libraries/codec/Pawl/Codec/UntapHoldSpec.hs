module Pawl.Codec.UntapHoldSpec where

import qualified Pawl.Codec.UntapHold as UntapHold
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.UntapHold as UntapHold

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.UntapHold" $ do
  Spec.it s "Elective" $
    Common.assertCodec
      s
      UntapHold.codec
      UntapHold.Elective
      " {\"type\":\"Elective\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s UntapHold.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s UntapHold.codec
