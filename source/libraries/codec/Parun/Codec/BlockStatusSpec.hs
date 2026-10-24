module Parun.Codec.BlockStatusSpec where

import qualified Parun.Codec.BlockStatus as BlockStatus
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockStatus as BlockStatus

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockStatus" $ do
  Spec.it s "Unblocked" $
    Common.assertCodec
      s
      BlockStatus.codec
      BlockStatus.Unblocked
      " {\"type\":\"Unblocked\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s BlockStatus.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockStatus.codec
