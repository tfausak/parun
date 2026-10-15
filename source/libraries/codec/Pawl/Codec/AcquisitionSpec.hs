module Pawl.Codec.AcquisitionSpec where

import qualified Pawl.Codec.Acquisition as Acquisition
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Acquisition as Acquisition
import qualified Pawl.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Acquisition" $ do
  Spec.it s "Own" $
    Common.assertCodec s Acquisition.codec Acquisition.Own " {\"type\":\"Own\"} "
  Spec.it s "Copied" $
    Common.assertCodec s Acquisition.codec (Acquisition.Copied (Timestamp.MkTimestamp 7)) " {\"type\":\"Copied\",\"value\":7} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Acquisition.codec
