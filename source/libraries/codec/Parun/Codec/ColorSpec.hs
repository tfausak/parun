module Parun.Codec.ColorSpec where

import qualified Parun.Codec.Color as Color
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Color" $ do
  Spec.it s "White" $
    Common.assertCodec
      s
      Color.codec
      Color.White
      " {\"type\":\"White\"} "
  Spec.it s "Blue" $
    Common.assertCodec
      s
      Color.codec
      Color.Blue
      " {\"type\":\"Blue\"} "
  Spec.it s "Black" $
    Common.assertCodec
      s
      Color.codec
      Color.Black
      " {\"type\":\"Black\"} "
  Spec.it s "Red" $
    Common.assertCodec
      s
      Color.codec
      Color.Red
      " {\"type\":\"Red\"} "
  Spec.it s "Green" $
    Common.assertCodec
      s
      Color.codec
      Color.Green
      " {\"type\":\"Green\"} "
  Spec.it s "unknown tag fails" $
    Spec.assertBool s (either (const True) (const False) (Codec.decode Color.codec (Value.object []))) "left"
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Color.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Color.codec
