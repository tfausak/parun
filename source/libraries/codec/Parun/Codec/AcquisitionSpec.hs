module Parun.Codec.AcquisitionSpec where

import qualified Parun.Codec.Acquisition as Acquisition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Acquisition" $ do
  Spec.it s "Own" $
    Common.assertCodec s Acquisition.codec Acquisition.Own " {\"type\":\"Own\"} "
  Spec.it s "Copied" $
    Common.assertCodec s Acquisition.codec (Acquisition.Copied (Timestamp.MkTimestamp 7)) " {\"type\":\"Copied\",\"value\":7} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Acquisition.codec
