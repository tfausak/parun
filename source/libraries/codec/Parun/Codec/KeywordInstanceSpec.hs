module Parun.Codec.KeywordInstanceSpec where

import qualified Parun.Codec.KeywordInstance as KeywordInstance
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.KeywordInstance as KeywordInstance
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.KeywordInstance" $ do
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
