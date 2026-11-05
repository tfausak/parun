module Parun.Codec.AttachmentEndSpec where

import qualified Parun.Codec.AttachmentEnd as AttachmentEnd
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachmentEnd as AttachmentEnd

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachmentEnd" $ do
  Spec.it s "Attachment" $
    Common.assertCodec s AttachmentEnd.codec AttachmentEnd.Attachment " {\"type\":\"Attachment\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AttachmentEnd.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachmentEnd.codec
