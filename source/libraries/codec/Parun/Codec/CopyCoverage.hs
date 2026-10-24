module Parun.Codec.CopyCoverage where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CopyCoverage as CopyCoverage

codec :: Codec.Codec CopyCoverage.CopyCoverage
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "These" (Common.set ObjectId.codec) CopyCoverage.These (\x -> case x of CopyCoverage.These y -> Just y; _ -> Nothing),
      Arm.payload "SourceHost" (Common.naturalMap ObjectId.codec Timestamp.codec) CopyCoverage.SourceHost (\x -> case x of CopyCoverage.SourceHost y -> Just y; _ -> Nothing),
      Arm.payload "Attachment" ObjectId.codec CopyCoverage.Attachment (\x -> case x of CopyCoverage.Attachment y -> Just y; _ -> Nothing)
    ]

tagOf :: CopyCoverage.CopyCoverage -> String
tagOf x = case x of
  CopyCoverage.These {} -> "These"
  CopyCoverage.SourceHost {} -> "SourceHost"
  CopyCoverage.Attachment {} -> "Attachment"
