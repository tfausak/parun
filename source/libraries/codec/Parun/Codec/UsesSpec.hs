module Parun.Codec.UsesSpec where

import qualified Parun.Codec.Uses as Uses
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Uses" $ do
  Spec.it s "Unlimited" $
    Common.assertCodec
      s
      Uses.codec
      Uses.Unlimited
      " {\"type\":\"Unlimited\"} "
  Spec.it s "Once" $
    Common.assertCodec
      s
      Uses.codec
      Uses.Once
      " {\"type\":\"Once\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Uses.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s Uses.codec
