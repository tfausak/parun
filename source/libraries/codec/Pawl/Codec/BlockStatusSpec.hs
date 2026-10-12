module Pawl.Codec.BlockStatusSpec where

import qualified Pawl.Codec.BlockStatus as BlockStatus
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.BlockStatus as BlockStatus

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.BlockStatus" $ do
  Spec.it s "Unblocked" $
    Common.assertCodec
      s
      BlockStatus.codec
      BlockStatus.Unblocked
      " {\"type\":\"Unblocked\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s BlockStatus.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockStatus.codec
