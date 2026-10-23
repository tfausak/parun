module Pawl.Codec.RevealObligationSpec where

import qualified Pawl.Codec.RevealObligation as RevealObligation
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.RevealObligation as RevealObligation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.RevealObligation" $ do
  Spec.it s "Mandatory" $
    Common.assertCodec
      s
      RevealObligation.codec
      RevealObligation.Mandatory
      " {\"type\":\"Mandatory\"} "
  Spec.it s "Optional" $
    Common.assertCodec
      s
      RevealObligation.codec
      RevealObligation.Optional
      " {\"type\":\"Optional\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives the
  -- arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s RevealObligation.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s RevealObligation.codec
