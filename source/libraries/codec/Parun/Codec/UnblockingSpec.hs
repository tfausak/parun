module Parun.Codec.UnblockingSpec where

import qualified Parun.Codec.Unblocking as Unblocking
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Unblocking as Unblocking

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Unblocking" $ do
  Spec.it s "SoleBlockedUnblocked" $
    Common.assertCodec
      s
      Unblocking.codec
      Unblocking.SoleBlockedUnblocked
      " \"SoleBlockedUnblocked\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Unblocking.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Unblocking.codec
