module Parun.Codec.ChoosePlayerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ChoosePlayer as ChoosePlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChoosePlayer as ChoosePlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChoosePlayer" $ do
  -- CR 608.2d's two printed sentences, so the pair catches a codec that read
  -- the scope off anything but the wire.
  Spec.it s "MkChoosePlayer, an opponent (Skullwinder)" $
    Common.assertCodec
      s
      ChoosePlayer.codec
      ( ChoosePlayer.MkChoosePlayer
          { ChoosePlayer.scope = PlayerScope.Related PlayerRelation.Opponent,
            ChoosePlayer.slot = SlotName.MkSlotName (Text.pack "opponent")
          }
      )
      " {\"scope\":{\"type\":\"Opponent\"},\"slot\":\"opponent\"} "
  Spec.it s "MkChoosePlayer, a player (Stadium Vendors)" $
    Common.assertCodec
      s
      ChoosePlayer.codec
      ( ChoosePlayer.MkChoosePlayer
          { ChoosePlayer.scope = PlayerScope.Related PlayerRelation.AnyPlayer,
            ChoosePlayer.slot = SlotName.MkSlotName (Text.pack "chosen")
          }
      )
      " {\"scope\":{\"type\":\"AnyPlayer\"},\"slot\":\"chosen\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChoosePlayer.codec
