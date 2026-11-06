module Parun.Codec.DealtDamageSpec where

import qualified Parun.Codec.DealtDamage as DealtDamage
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.PlayerRef as PlayerRef.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealtDamage" $ do
  Spec.it s "any damage omits the kind" $
    Common.assertCodec
      s
      (DealtDamage.codec PlayerRef.codec)
      (DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRef.Type.Relative PlayerRelation.Type.Opponent, DealtDamage.kind = Nothing, DealtDamage.by = Nothing})
      " {\"recipient\":{\"type\":\"Relative\",\"value\":\"Opponent\"}} "
  Spec.it s "combat damage alone" $
    Common.assertCodec
      s
      (DealtDamage.codec PlayerRef.codec)
      (DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRef.Type.Relative PlayerRelation.Type.AnyPlayer, DealtDamage.kind = Just DamageKind.Combat, DealtDamage.by = Nothing})
      " {\"recipient\":{\"type\":\"Relative\",\"value\":\"AnyPlayer\"},\"kind\":\"Combat\"} "
  Spec.it s "a relation for the player" $
    Common.assertCodec
      s
      (DealtDamage.codec PlayerRelation.codec)
      (DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRelation.Type.Opponent, DealtDamage.kind = Just DamageKind.Noncombat, DealtDamage.by = Nothing})
      " {\"recipient\":\"Opponent\",\"kind\":\"Noncombat\"} "
  Spec.it s "damage from a source of a card type" $
    Common.assertCodec
      s
      (DealtDamage.codec PlayerRef.codec)
      (DealtDamage.MkDealtDamage {DealtDamage.recipient = PlayerRef.Type.Relative PlayerRelation.Type.You, DealtDamage.kind = Nothing, DealtDamage.by = Just CardType.Artifact})
      " {\"recipient\":{\"type\":\"Relative\",\"value\":\"You\"},\"by\":\"Artifact\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (DealtDamage.codec PlayerRef.codec)
