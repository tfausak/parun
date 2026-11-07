module Parun.Codec.AloneAmongSpec where

import qualified Parun.Codec.AloneAmong as AloneAmong
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AloneAmong as AloneAmong

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AloneAmong" $ do
  Spec.it s "AttackersOfItsPlayer" $
    Common.assertCodec
      s
      AloneAmong.codec
      AloneAmong.AttackersOfItsPlayer
      " \"AttackersOfItsPlayer\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AloneAmong.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s AloneAmong.codec
