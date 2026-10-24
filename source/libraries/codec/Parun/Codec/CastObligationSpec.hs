module Parun.Codec.CastObligationSpec where

import qualified Parun.Codec.CastObligation as CastObligation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastObligation as CastObligation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastObligation" $ do
  Spec.it s "Mandatory" $
    Common.assertCodec
      s
      CastObligation.codec
      CastObligation.Mandatory
      " {\"type\":\"Mandatory\"} "
  Spec.it s "Optional" $
    Common.assertCodec
      s
      CastObligation.codec
      CastObligation.Optional
      " {\"type\":\"Optional\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives the
  -- arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CastObligation.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s CastObligation.codec
