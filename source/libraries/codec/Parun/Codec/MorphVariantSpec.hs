module Parun.Codec.MorphVariantSpec where

import qualified Parun.Codec.MorphVariant as MorphVariant
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.MorphVariant as MorphVariant

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MorphVariant" $ do
  Spec.it s "Plain (CR 702.37a)" $
    Common.assertCodec
      s
      MorphVariant.codec
      MorphVariant.Plain
      " {\"type\":\"Plain\"} "
  Spec.it s "Mega (CR 702.37b)" $
    Common.assertCodec
      s
      MorphVariant.codec
      MorphVariant.Mega
      " {\"type\":\"Mega\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s MorphVariant.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s MorphVariant.codec
