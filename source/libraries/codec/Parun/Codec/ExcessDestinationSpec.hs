module Parun.Codec.ExcessDestinationSpec where

import qualified Parun.Codec.ExcessDestination as ExcessDestination
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExcessDestination as ExcessDestination

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExcessDestination" $ do
  Spec.it s "ToRecipientController" $
    Common.assertCodec
      s
      ExcessDestination.codec
      ExcessDestination.ToRecipientController
      " {\"type\":\"ToRecipientController\"} "
  -- Exhaustive where the literal above is representative: Arm.enum derives the
  -- arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ExcessDestination.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ExcessDestination.codec
