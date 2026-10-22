module Pawl.Codec.WordFamilySpec where

import qualified Pawl.Codec.WordFamily as WordFamily
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.WordFamily as WordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.WordFamily" $ do
  Spec.it s "BasicLandType" $
    Common.assertCodec
      s
      WordFamily.codec
      WordFamily.BasicLandType
      " {\"type\":\"BasicLandType\"} "
  Spec.it s "CreatureType" $
    Common.assertCodec
      s
      WordFamily.codec
      WordFamily.CreatureType
      " {\"type\":\"CreatureType\"} "
  Spec.it s "EnchantmentType" $
    Common.assertCodec
      s
      WordFamily.codec
      WordFamily.EnchantmentType
      " {\"type\":\"EnchantmentType\"} "
  Spec.it s "Color" $
    Common.assertCodec
      s
      WordFamily.codec
      WordFamily.Color
      " {\"type\":\"Color\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s WordFamily.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s WordFamily.codec
