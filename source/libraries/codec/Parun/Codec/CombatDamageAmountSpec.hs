module Parun.Codec.CombatDamageAmountSpec where

import qualified Parun.Codec.CombatDamageAmount as CombatDamageAmount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CombatDamageAmount as CombatDamageAmount.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CombatDamageAmount" $ do
  Spec.it s "NoCombatDamage" $
    Common.assertCodec s CombatDamageAmount.codec CombatDamageAmount.Type.NoCombatDamage " {\"type\":\"NoCombatDamage\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CombatDamageAmount.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CombatDamageAmount.codec
