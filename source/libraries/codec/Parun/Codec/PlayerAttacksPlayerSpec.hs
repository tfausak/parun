module Parun.Codec.PlayerAttacksPlayerSpec where

import qualified Parun.Codec.PlayerAttacksPlayer as PlayerAttacksPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackedPlayer as AttackedPlayer
import qualified Parun.Types.PlayerAttacksPlayer as PlayerAttacksPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerAttacksPlayer" $ do
  -- Lulu, Stern Guardian's payload: who declared, and whom they declared
  -- against. The two keys hold DIFFERENT relations here, so a codec that
  -- crossed them would not round-trip.
  Spec.it s "MkPlayerAttacksPlayer, both keys" $
    Common.assertCodec
      s
      PlayerAttacksPlayer.codec
      ( PlayerAttacksPlayer.MkPlayerAttacksPlayer
          { PlayerAttacksPlayer.attacker = PlayerRelation.Opponent,
            PlayerAttacksPlayer.attacked = AttackedPlayer.Related PlayerRelation.You
          }
      )
      " {\"attacker\":{\"type\":\"Opponent\"},\"attacked\":{\"type\":\"Related\",\"value\":{\"type\":\"You\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerAttacksPlayer.codec
