module Parun.Codec.ReplacementProvenanceSpec where

import qualified Parun.Codec.ReplacementProvenance as ReplacementProvenance
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ReplacementProvenance as ReplacementProvenance

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ReplacementProvenance" $ do
  Spec.it s "Printed" $
    Common.assertCodec
      s
      ReplacementProvenance.codec
      ReplacementProvenance.Printed
      " {\"type\":\"Printed\"} "
  Spec.it s "Minted" $
    Common.assertCodec
      s
      ReplacementProvenance.codec
      ReplacementProvenance.Minted
      " {\"type\":\"Minted\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives the
  -- arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ReplacementProvenance.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ReplacementProvenance.codec
