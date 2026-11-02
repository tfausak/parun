module Parun.Codec.ProhibitionSpec where

import qualified Parun.Codec.Prohibition as Prohibition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Prohibition as Prohibition

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Prohibition" $ do
  Spec.it s "Regenerate" $
    Common.assertCodec
      s
      Prohibition.codec
      Prohibition.Regenerate
      " {\"type\":\"Regenerate\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Prohibition.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Prohibition.codec
  Spec.it s "PhaseIn" $
    Common.assertCodec
      s
      Prohibition.codec
      Prohibition.PhaseIn
      " {\"type\":\"PhaseIn\"} "
