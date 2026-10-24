module Parun.Codec.PermissionPoolSpec where

import qualified Parun.Codec.PermissionPool as PermissionPool
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.PermissionPool as PermissionPool

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermissionPool" $ do
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
