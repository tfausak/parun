module Parun.Codec.ManaRiderEffectSpec where

import qualified Parun.Codec.ManaRiderEffect as ManaRiderEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ManaRiderEffect as ManaRiderEffect

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaRiderEffect" $ do
  Spec.it s "CantBeCountered" $
    Common.assertCodec
      s
      ManaRiderEffect.codec
      ManaRiderEffect.CantBeCountered
      " {\"type\":\"CantBeCountered\"} "
  Spec.it s "GainsHasteUntilEndOfTurn" $
    Common.assertCodec
      s
      ManaRiderEffect.codec
      ManaRiderEffect.GainsHasteUntilEndOfTurn
      " {\"type\":\"GainsHasteUntilEndOfTurn\"} "
  -- Arm.enum derives the arm list from the type, so this is what catches a
  -- payload that encoded like another.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ManaRiderEffect.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaRiderEffect.codec
