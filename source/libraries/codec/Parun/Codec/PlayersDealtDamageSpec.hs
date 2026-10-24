module Parun.Codec.PlayersDealtDamageSpec where

import qualified Parun.Codec.PlayersDealtDamage as PlayersDealtDamage
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayersDealtDamage as PlayersDealtDamage

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayersDealtDamage" $ do
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
