module Parun.Codec.PermanentDealsCombatDamageToPlayerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentDealsCombatDamageToPlayer" $ do
  -- The two keys name different relations, so a codec that crossed them would
  -- not round-trip.
  Spec.it s "MkPermanentDealsCombatDamageToPlayer, both keys" $
    Common.assertCodec
      s
      PermanentDealsCombatDamageToPlayer.codec
      ( PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer
          { PermanentDealsCombatDamageToPlayer.filter = Filter.HeldBy Holder.Controller PlayerRelation.Opponent,
            PermanentDealsCombatDamageToPlayer.recipient = PlayerRelation.You,
            PermanentDealsCombatDamageToPlayer.orTheirPlaneswalkers = False
          }
      )
      " {\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"Opponent\"}}},\"recipient\":{\"type\":\"You\"}} "
  Spec.it s "MkPermanentDealsCombatDamageToPlayer, or their planeswalkers" $
    Common.assertCodec
      s
      PermanentDealsCombatDamageToPlayer.codec
      ( PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer
          { PermanentDealsCombatDamageToPlayer.filter = Filter.IsBound (SlotName.MkSlotName (Text.pack "target")),
            PermanentDealsCombatDamageToPlayer.recipient = PlayerRelation.AnyPlayer,
            PermanentDealsCombatDamageToPlayer.orTheirPlaneswalkers = True
          }
      )
      " {\"filter\":{\"type\":\"IsBound\",\"value\":\"target\"},\"orTheirPlaneswalkers\":true,\"recipient\":{\"type\":\"AnyPlayer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentDealsCombatDamageToPlayer.codec
