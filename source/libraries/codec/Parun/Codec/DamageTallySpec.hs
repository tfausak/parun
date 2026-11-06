module Parun.Codec.DamageTallySpec where

import qualified Parun.Codec.DamageTally as DamageTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamageTally as DamageTally
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.WhichTurn as WhichTurn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageTally" $ do
  Spec.it s "this turn omits the turn" $
    Common.assertCodec
      s
      DamageTally.codec
      (DamageTally.MkDamageTally {DamageTally.dealt = DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRef.Relative PlayerRelation.Opponent, DealtDamage.kind = Nothing, DealtDamage.by = Nothing}, DamageTally.turn = WhichTurn.ThisTurn})
      " {\"recipient\":{\"type\":\"Relative\",\"value\":\"Opponent\"}} "
  Spec.it s "last turn, noncombat damage" $
    Common.assertCodec
      s
      DamageTally.codec
      (DamageTally.MkDamageTally {DamageTally.dealt = DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRef.Relative PlayerRelation.Opponent, DealtDamage.kind = Just DamageKind.Noncombat, DealtDamage.by = Nothing}, DamageTally.turn = WhichTurn.LastTurn})
      " {\"kind\":\"Noncombat\",\"recipient\":{\"type\":\"Relative\",\"value\":\"Opponent\"},\"turn\":\"LastTurn\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DamageTally.codec
