module Parun.Codec.RoundingSpec where

import qualified Parun.Codec.Rounding as Rounding
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Rounding as Rounding

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Rounding" $ do
  Spec.it s "Up" $
    Common.assertCodec
      s
      Rounding.codec
      Rounding.Up
      " {\"type\":\"Up\"} "
  Spec.it s "Down" $
    Common.assertCodec
      s
      Rounding.codec
      Rounding.Down
      " {\"type\":\"Down\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Rounding.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Rounding.codec
