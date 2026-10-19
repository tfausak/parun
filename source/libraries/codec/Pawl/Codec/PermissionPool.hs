module Pawl.Codec.PermissionPool where

import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.PermissionPool as PermissionPool

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
