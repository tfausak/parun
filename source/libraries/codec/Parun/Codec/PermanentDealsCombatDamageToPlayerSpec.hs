module Parun.Codec.PermanentDealsCombatDamageToPlayerSpec where

import qualified Parun.Codec.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentDealsCombatDamageToPlayer" $ do
  -- The two keys name different relations, so a codec that crossed them would
  -- not round-trip.
  Spec.it s "MkPermanentDealsCombatDamageToPlayer, both keys" $
    Common.assertCodec
      s
      PermanentDealsCombatDamageToPlayer.codec
      ( PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer
          { PermanentDealsCombatDamageToPlayer.filter = Filter.ControlledBy PlayerRelation.Opponent,
            PermanentDealsCombatDamageToPlayer.recipient = PlayerRelation.You
          }
      )
      " {\"filter\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"Opponent\"}},\"recipient\":{\"type\":\"You\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentDealsCombatDamageToPlayer.codec
