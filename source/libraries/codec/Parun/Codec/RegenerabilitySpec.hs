module Parun.Codec.RegenerabilitySpec where

import qualified Parun.Codec.Regenerability as Regenerability
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Regenerability as Regenerability

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Regenerability" $ do
  Spec.it s "Regenerable" $
    Common.assertCodec
      s
      Regenerability.codec
      Regenerability.Regenerable
      " {\"type\":\"Regenerable\"} "
  Spec.it s "CantBeRegenerated" $
    Common.assertCodec
      s
      Regenerability.codec
      Regenerability.CantBeRegenerated
      " {\"type\":\"CantBeRegenerated\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Regenerability.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Regenerability.codec
