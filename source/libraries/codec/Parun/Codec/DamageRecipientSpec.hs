module Parun.Codec.DamageRecipientSpec where

import qualified Parun.Codec.DamageRecipient as DamageRecipient
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DamageRecipient as DamageRecipient
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageRecipient" $ do
  -- Questing Beast's "to an opponent".
  Spec.it s "Player" $
    Common.assertCodec
      s
      DamageRecipient.codec
      (DamageRecipient.Player PlayerRelation.Opponent)
      " {\"type\":\"Player\",\"value\":\"Opponent\"} "
  -- Phage the Untouchable's "to a creature".
  Spec.it s "Permanent" $
    Common.assertCodec
      s
      DamageRecipient.codec
      (DamageRecipient.Permanent CardType.Creature)
      " {\"type\":\"Permanent\",\"value\":\"Creature\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DamageRecipient.codec
