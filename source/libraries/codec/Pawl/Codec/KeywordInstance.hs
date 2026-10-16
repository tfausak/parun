module Pawl.Codec.KeywordInstance where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.Timestamp as Timestamp
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.KeywordInstance as KeywordInstance

codec :: Codec.Codec KeywordInstance.KeywordInstance
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Own" Common.natural KeywordInstance.Own (\x -> case x of KeywordInstance.Own n -> Just n; _ -> Nothing),
      Arm.payload "Granted" (Common.tuple (Common.tuple ObjectId.codec Timestamp.codec) Common.natural) (\((o, t), n) -> KeywordInstance.Granted o t n) (\x -> case x of KeywordInstance.Granted o t n -> Just ((o, t), n); _ -> Nothing)
    ]

tagOf :: KeywordInstance.KeywordInstance -> String
tagOf x = case x of
  KeywordInstance.Own {} -> "Own"
  KeywordInstance.Granted {} -> "Granted"
