module Pawl.Codec.PlayersDealtDamageSpec where

import qualified Pawl.Codec.PlayersDealtDamage as PlayersDealtDamage
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.DamageKind as DamageKind
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayersDealtDamage as PlayersDealtDamage

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayersDealtDamage" $ do
  Spec.it s "any damage omits the kind" $
    Common.assertCodec
      s
      PlayersDealtDamage.codec
      (PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = PlayerRef.Relative PlayerRelation.Opponent, PlayersDealtDamage.kind = Nothing})
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}}} "
  Spec.it s "combat damage alone" $
    Common.assertCodec
      s
      PlayersDealtDamage.codec
      (PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = PlayerRef.Relative PlayerRelation.AnyPlayer, PlayersDealtDamage.kind = Just DamageKind.Combat})
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"kind\":{\"type\":\"Combat\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayersDealtDamage.codec
