module Pawl.Codec.CopyDomain where

import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.Codec.Zone as Zone
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.CopyDomain as CopyDomain

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
