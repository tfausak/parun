module Parun.Codec.PermissionPool where

import qualified Parun.Codec.ExiledPile as ExiledPile
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PermissionPool as PermissionPool

codec :: Codec.Codec PermissionPool.PermissionPool
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "EveryCard" PermissionPool.EveryCard,
      Arm.payload "InExiledPile" ExiledPile.codec PermissionPool.InExiledPile (\x -> case x of PermissionPool.InExiledPile y -> Just y; _ -> Nothing)
    ]

tagOf :: PermissionPool.PermissionPool -> String
tagOf x = case x of
  PermissionPool.EveryCard -> "EveryCard"
  PermissionPool.InExiledPile {} -> "InExiledPile"
