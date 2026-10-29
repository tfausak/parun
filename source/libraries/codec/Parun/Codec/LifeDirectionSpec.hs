module Parun.Codec.LifeDirectionSpec where

import qualified Parun.Codec.LifeDirection as LifeDirection
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeDirection as LifeDirection

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeDirection" $ do
  Spec.it s "Gained" $
    Common.assertCodec
      s
      LifeDirection.codec
      LifeDirection.Gained
      " {\"type\":\"Gained\"} "
  Spec.it s "Lost" $
    Common.assertCodec
      s
      LifeDirection.codec
      LifeDirection.Lost
      " {\"type\":\"Lost\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s LifeDirection.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeDirection.codec
