module Parun.Codec.HiddenZoneSpec where

import qualified Parun.Codec.HiddenZone as HiddenZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.HiddenZone as HiddenZone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.HiddenZone" $ do
  Spec.it s "Hand" $
    Common.assertCodec
      s
      HiddenZone.codec
      HiddenZone.Hand
      " \"Hand\" "
  Spec.it s "Library" $
    Common.assertCodec
      s
      HiddenZone.codec
      HiddenZone.Library
      " \"Library\" "
