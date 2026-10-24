module Parun.Codec.TraitSpec where

import qualified Parun.Codec.Trait as Trait
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Trait as Trait

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Trait" $ do
  Spec.it s "Sector" $
    Common.assertCodec
      s
      Trait.codec
      Trait.Sector
      " {\"type\":\"Sector\"} "
  -- Parun.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Trait.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Trait.codec
