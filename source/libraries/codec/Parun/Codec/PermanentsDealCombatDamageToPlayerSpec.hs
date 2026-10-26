module Parun.Codec.PermanentsDealCombatDamageToPlayerSpec where

import qualified Parun.Codec.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentsDealCombatDamageToPlayer" $ do
  -- Norn's Decree's payload: the damagers an opponent controls, and CR 109.5's
  -- "you" as the damaged player. The two keys name different relations, so a
  -- codec that crossed them would not round-trip.
  Spec.it s "MkPermanentsDealCombatDamageToPlayer, both keys" $
    Common.assertCodec
      s
      PermanentsDealCombatDamageToPlayer.codec
      ( PermanentsDealCombatDamageToPlayer.MkPermanentsDealCombatDamageToPlayer
          { PermanentsDealCombatDamageToPlayer.filter = Filter.HeldBy Holder.Controller PlayerRelation.Opponent,
            PermanentsDealCombatDamageToPlayer.recipient = PlayerRelation.You,
            PermanentsDealCombatDamageToPlayer.oneOrMorePlayers = False
          }
      )
      " {\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"Opponent\"}}},\"recipient\":{\"type\":\"You\"}} "
  -- Forth Eorlingas!'s "to one or more players": the key appears only when set.
  Spec.it s "MkPermanentsDealCombatDamageToPlayer, one or more players" $
    Common.assertCodec
      s
      PermanentsDealCombatDamageToPlayer.codec
      ( PermanentsDealCombatDamageToPlayer.MkPermanentsDealCombatDamageToPlayer
          { PermanentsDealCombatDamageToPlayer.filter = Filter.HeldBy Holder.Controller PlayerRelation.You,
            PermanentsDealCombatDamageToPlayer.recipient = PlayerRelation.AnyPlayer,
            PermanentsDealCombatDamageToPlayer.oneOrMorePlayers = True
          }
      )
      " {\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},\"oneOrMorePlayers\":true,\"recipient\":{\"type\":\"AnyPlayer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentsDealCombatDamageToPlayer.codec
