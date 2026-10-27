module Parun.Codec.PlayerIsDealtDamageSpec where

import qualified Parun.Codec.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerIsDealtDamage" $ do
  Spec.it s "the player alone omits orTheirPlaneswalkers" $
    Common.assertCodec
      s
      PlayerIsDealtDamage.codec
      (PlayerIsDealtDamage.MkPlayerIsDealtDamage {PlayerIsDealtDamage.dealt = DealtDamage.MkDealtDamage PlayerRelation.You Nothing, PlayerIsDealtDamage.orTheirPlaneswalkers = False})
      " {\"dealt\":{\"player\":{\"type\":\"You\"}}} "
  Spec.it s "the player or their planeswalkers" $
    Common.assertCodec
      s
      PlayerIsDealtDamage.codec
      (PlayerIsDealtDamage.MkPlayerIsDealtDamage {PlayerIsDealtDamage.dealt = DealtDamage.MkDealtDamage PlayerRelation.You (Just DamageKind.Combat), PlayerIsDealtDamage.orTheirPlaneswalkers = True})
      " {\"dealt\":{\"player\":{\"type\":\"You\"},\"kind\":{\"type\":\"Combat\"}},\"orTheirPlaneswalkers\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerIsDealtDamage.codec
