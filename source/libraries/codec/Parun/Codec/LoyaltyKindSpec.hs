module Parun.Codec.LoyaltyKindSpec where

import qualified Parun.Codec.LoyaltyKind as LoyaltyKind
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LoyaltyKind as LoyaltyKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LoyaltyKind" $ do
  Spec.it s "LoyaltyAbility" $
    Common.assertCodec
      s
      LoyaltyKind.codec
      LoyaltyKind.LoyaltyAbility
      " {\"type\":\"LoyaltyAbility\"} "

  Spec.it s "NonLoyaltyAbility" $
    Common.assertCodec
      s
      LoyaltyKind.codec
      LoyaltyKind.NonLoyaltyAbility
      " {\"type\":\"NonLoyaltyAbility\"} "

  -- Exhaustive where the two above are literal, Parun.Codec.AbilityKindSpec's
  -- posture: Arm.enum derives its arms from the type.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s LoyaltyKind.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s LoyaltyKind.codec
