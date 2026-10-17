module Pawl.Codec.CopyCoverage where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.Timestamp as Timestamp
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.CopyCoverage as CopyCoverage

codec :: Codec.Codec CopyCoverage.CopyCoverage
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "These" (Common.set ObjectId.codec) CopyCoverage.These (\x -> case x of CopyCoverage.These y -> Just y; _ -> Nothing),
      Arm.payload "SourceHost" (Common.naturalMap ObjectId.codec Timestamp.codec) CopyCoverage.SourceHost (\x -> case x of CopyCoverage.SourceHost y -> Just y; _ -> Nothing)
    ]

tagOf :: CopyCoverage.CopyCoverage -> String
tagOf x = case x of
  CopyCoverage.These {} -> "These"
  CopyCoverage.SourceHost {} -> "SourceHost"
