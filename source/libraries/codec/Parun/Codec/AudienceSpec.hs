module Parun.Codec.AudienceSpec where

import qualified Parun.Codec.Audience as Audience
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Audience as Audience

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Audience" $ do
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
