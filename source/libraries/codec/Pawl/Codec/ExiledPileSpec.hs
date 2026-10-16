module Pawl.Codec.ExiledPileSpec where

import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ExiledPile as ExiledPile

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExiledPile" $ do
  Spec.it s "CraftMaterials" $
    Common.assertCodec s ExiledPile.codec ExiledPile.CraftMaterials " {\"type\":\"CraftMaterials\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ExiledPile.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ExiledPile.codec
