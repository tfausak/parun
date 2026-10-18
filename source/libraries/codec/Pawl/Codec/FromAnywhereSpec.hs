module Pawl.Codec.FromAnywhereSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.FromAnywhere as FromAnywhere
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.FromAnywhere as FromAnywhere
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.FromAnywhere" $ do
  Spec.it s "MkFromAnywhere, no among" $
    Common.assertCodec
      s
      FromAnywhere.codec
      (FromAnywhere.MkFromAnywhere {FromAnywhere.slot = SlotName.MkSlotName (Text.pack "self"), FromAnywhere.among = Nothing})
      " {\"slot\":\"self\"} "
  Spec.it s "MkFromAnywhere, both keys" $
    Common.assertCodec
      s
      FromAnywhere.codec
      (FromAnywhere.MkFromAnywhere {FromAnywhere.slot = SlotName.MkSlotName (Text.pack "self"), FromAnywhere.among = Just (SlotName.MkSlotName (Text.pack "exiled"))})
      " {\"slot\":\"self\",\"among\":\"exiled\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s FromAnywhere.codec
