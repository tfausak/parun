module Parun.Codec.TriggerSourceSpec where

import qualified Parun.Codec.TriggerSource as TriggerSource
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.TriggerSource as TriggerSource

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggerSource" $ do
  -- CR 113.7: the object whose ability triggered.
  Spec.it s "OfObject" $
    Common.assertCodec
      s
      TriggerSource.codec
      (TriggerSource.OfObject (ObjectId.MkObjectId 4))
      " {\"type\":\"OfObject\",\"value\":4} "
  -- CR 725.2 / CR 702.179d: no object to name.
  Spec.it s "Sourceless" $
    Common.assertCodec
      s
      TriggerSource.codec
      TriggerSource.Sourceless
      " {\"type\":\"Sourceless\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TriggerSource.codec
