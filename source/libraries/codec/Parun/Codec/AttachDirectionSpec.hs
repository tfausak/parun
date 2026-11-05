module Parun.Codec.AttachDirectionSpec where

import qualified Parun.Codec.AttachDirection as AttachDirection
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachDirection as AttachDirection

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachDirection" $ do
  Spec.it s "Unattaches" $
    Common.assertCodec s AttachDirection.codec AttachDirection.Unattaches " {\"type\":\"Unattaches\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AttachDirection.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachDirection.codec
