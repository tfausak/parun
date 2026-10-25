module Parun.Codec.BlockRoleSpec where

import qualified Parun.Codec.BlockRole as BlockRole
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockRole as BlockRole

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockRole" $ do
  Spec.it s "Blocker" $
    Common.assertCodec
      s
      BlockRole.codec
      BlockRole.Blocker
      " {\"type\":\"Blocker\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s BlockRole.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockRole.codec
