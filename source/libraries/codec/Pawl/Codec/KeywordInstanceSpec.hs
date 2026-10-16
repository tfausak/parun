module Pawl.Codec.KeywordInstanceSpec where

import qualified Pawl.Codec.KeywordInstance as KeywordInstance
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.KeywordInstance as KeywordInstance
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.KeywordInstance" $ do
  Spec.it s "Own" $
    Common.assertCodec
      s
      KeywordInstance.codec
      (KeywordInstance.Own 2)
      " {\"type\":\"Own\",\"value\":2} "
  Spec.it s "Granted" $
    Common.assertCodec
      s
      KeywordInstance.codec
      (KeywordInstance.Granted (ObjectId.MkObjectId 7) (Timestamp.MkTimestamp 3) 1)
      " {\"type\":\"Granted\",\"value\":[[7,3],1]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s KeywordInstance.codec
