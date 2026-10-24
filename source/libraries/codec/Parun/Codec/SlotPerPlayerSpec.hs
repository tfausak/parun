module Parun.Codec.SlotPerPlayerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.SlotPerPlayer as SlotPerPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SlotPerPlayer as SlotPerPlayer

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SlotPerPlayer" $ do
  Spec.it s "MkSlotPerPlayer, each opponent (Riptide Gearhulk)" $
    Common.assertCodec
      s
      SlotPerPlayer.codec
      ( SlotPerPlayer.MkSlotPerPlayer
          { SlotPerPlayer.players = PlayerRelation.Opponent,
            SlotPerPlayer.slot = SlotName.MkSlotName (Text.pack "thatPlayer")
          }
      )
      " {\"players\":{\"type\":\"Opponent\"},\"slot\":\"thatPlayer\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SlotPerPlayer.codec
