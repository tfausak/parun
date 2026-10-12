module Pawl.Codec.AudienceSpec where

import qualified Pawl.Codec.Audience as Audience
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Audience as Audience

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Audience" $ do
  Spec.it s "Everyone" $
    Common.assertCodec
      s
      Audience.codec
      Audience.Everyone
      " {\"type\":\"Everyone\"} "
  Spec.it s "ThatPlayer" $
    Common.assertCodec
      s
      Audience.codec
      Audience.ThatPlayer
      " {\"type\":\"ThatPlayer\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Audience.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Audience.codec
