module Parun.Codec.ComparisonSpec where

import qualified Parun.Codec.Comparison as Comparison
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Comparison as Comparison

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Comparison" $ do
  Spec.it s "Exactly" $
    Common.assertCodec
      s
      Comparison.codec
      Comparison.Exactly
      " {\"type\":\"Exactly\"} "
  Spec.it s "AtLeast" $
    Common.assertCodec
      s
      Comparison.codec
      Comparison.AtLeast
      " {\"type\":\"AtLeast\"} "
  Spec.it s "AtMost" $
    Common.assertCodec
      s
      Comparison.codec
      Comparison.AtMost
      " {\"type\":\"AtMost\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Comparison.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Comparison.codec
