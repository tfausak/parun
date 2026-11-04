module Parun.Codec.CardSelectionSpec where

import qualified Parun.Codec.CardSelection as CardSelection
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardSelection as CardSelection

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardSelection" $ do
  Spec.it s "ByChoice" $
    Common.assertCodec
      s
      CardSelection.codec
      CardSelection.ByChoice
      " {\"type\":\"ByChoice\"} "
  -- Exhaustive where the literal above is representative: Arm.enum derives the
  -- arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CardSelection.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s CardSelection.codec
