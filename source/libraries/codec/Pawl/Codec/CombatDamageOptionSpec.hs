module Pawl.Codec.CombatDamageOptionSpec where

import qualified Pawl.Codec.CombatDamageOption as CombatDamageOption
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CombatDamageOption as CombatDamageOption.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.CombatDamageOption" $ do
  Spec.it s "AsThoughUnblocked" $
    Common.assertCodec s CombatDamageOption.codec CombatDamageOption.Type.AsThoughUnblocked " {\"type\":\"AsThoughUnblocked\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CombatDamageOption.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CombatDamageOption.codec
