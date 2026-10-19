module Pawl.Codec.PermissionPoolSpec where

import qualified Pawl.Codec.PermissionPool as PermissionPool
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ExiledPile as ExiledPile
import qualified Pawl.Types.PermissionPool as PermissionPool

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PermissionPool" $ do
  Spec.it s "EveryCard" $
    Common.assertCodec
      s
      PermissionPool.codec
      PermissionPool.EveryCard
      " {\"type\":\"EveryCard\"} "
  Spec.it s "InExiledPile" $
    Common.assertCodec
      s
      PermissionPool.codec
      (PermissionPool.InExiledPile ExiledPile.OwnAbilities)
      " {\"type\":\"InExiledPile\",\"value\":{\"type\":\"OwnAbilities\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PermissionPool.codec
