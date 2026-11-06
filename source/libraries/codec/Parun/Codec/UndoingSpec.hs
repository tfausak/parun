module Parun.Codec.UndoingSpec where

import qualified Parun.Codec.Undoing as Undoing
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Undoing as Undoing

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Undoing" $ do
  Spec.it s "UnpaidCost" $
    Common.assertCodec
      s
      Undoing.codec
      Undoing.UnpaidCost
      " \"UnpaidCost\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Undoing.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Undoing.codec
