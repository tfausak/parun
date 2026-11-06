module Parun.Codec.DamageTriggerSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.DamageTrigger as DamageTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamageRecipient as DamageRecipient
import qualified Parun.Types.DamageTrigger as DamageTrigger
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageTrigger" $ do
  -- Spirit Link's host: any kind, any recipient, so no defaulted key.
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      DamageTrigger.codec
      (DamageTrigger.MkDamageTrigger ActingPermanent.Self Nothing Set.empty)
      " {\"actor\":{\"type\":\"Self\"}} "
  -- Garruk's Harbinger's "combat damage to a player or planeswalker".
  Spec.it s "a kind and recipients write their keys" $
    Common.assertCodec
      s
      DamageTrigger.codec
      (DamageTrigger.MkDamageTrigger ActingPermanent.Self (Just DamageKind.Combat) (Set.fromList [DamageRecipient.Player PlayerRelation.AnyPlayer, DamageRecipient.Permanent CardType.Planeswalker]))
      " {\"actor\":{\"type\":\"Self\"},\"kind\":\"Combat\",\"recipients\":[{\"type\":\"Player\",\"value\":\"AnyPlayer\"},{\"type\":\"Permanent\",\"value\":\"Planeswalker\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DamageTrigger.codec
