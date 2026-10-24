{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Draw where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Draw as Draw

-- | The slot is ELIDED when absent, as Mill's is.
codec :: Codec.Codec Draw.Draw
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec Draw.player
  quantity <- Fields.required "quantity" Quantity.codec Draw.quantity
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Draw.slot
  pure
    Draw.MkDraw
      { Draw.player = player,
        Draw.quantity = quantity,
        Draw.slot = slot
      }
