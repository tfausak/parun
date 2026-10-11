module Pawl.Codec.ExiledWithSpec where

import qualified Pawl.Codec.ExiledWith as ExiledWith
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ExiledWith as ExiledWith

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExiledWith" $ do
  Spec.it s "ExiledAsItEntered" $
    Common.assertCodec
      s
      ExiledWith.codec
      ExiledWith.ExiledAsItEntered
      " {\"type\":\"ExiledAsItEntered\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ExiledWith.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ExiledWith.codec
