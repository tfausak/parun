module Parun.Codec.CopyDomain where

import qualified Parun.Codec.ExiledPile as ExiledPile
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CopyDomain as CopyDomain

codec :: Codec.Codec CopyDomain.CopyDomain
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "InZone" Zone.codec CopyDomain.InZone (\x -> case x of CopyDomain.InZone y -> Just y; _ -> Nothing),
      Arm.payload "InPile" ExiledPile.codec CopyDomain.InPile (\x -> case x of CopyDomain.InPile y -> Just y; _ -> Nothing)
    ]

tagOf :: CopyDomain.CopyDomain -> String
tagOf x = case x of
  CopyDomain.InZone {} -> "InZone"
  CopyDomain.InPile {} -> "InPile"
