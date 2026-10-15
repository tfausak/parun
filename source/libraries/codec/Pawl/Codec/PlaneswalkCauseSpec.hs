module Pawl.Codec.PlaneswalkCauseSpec where

import qualified Pawl.Codec.PlaneswalkCause as PlaneswalkCause
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.PlaneswalkCause as PlaneswalkCause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlaneswalkCause" $ do
  Spec.it s "PlanarDie" $
    Common.assertCodec s PlaneswalkCause.codec PlaneswalkCause.PlanarDie " {\"type\":\"PlanarDie\"} "
  Spec.it s "Phenomenon" $
    Common.assertCodec s PlaneswalkCause.codec PlaneswalkCause.Phenomenon " {\"type\":\"Phenomenon\"} "
  Spec.it s "OwnerLeft" $
    Common.assertCodec s PlaneswalkCause.codec PlaneswalkCause.OwnerLeft " {\"type\":\"OwnerLeft\"} "
  Spec.it s "Instruction" $
    Common.assertCodec s PlaneswalkCause.codec PlaneswalkCause.Instruction " {\"type\":\"Instruction\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlaneswalkCause.codec
