module Parun.Codec.CopyRecipientSpec where

import qualified Parun.Codec.CopyRecipient as CopyRecipient
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CopyRecipient as CopyRecipient

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CopyRecipient" $ do
  Spec.it s "ItsHost" $
    Common.assertCodec s CopyRecipient.codec CopyRecipient.ItsHost " {\"type\":\"ItsHost\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CopyRecipient.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CopyRecipient.codec
