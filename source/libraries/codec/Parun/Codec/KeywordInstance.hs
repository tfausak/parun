module Parun.Codec.KeywordInstance where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.KeywordInstance as KeywordInstance

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
