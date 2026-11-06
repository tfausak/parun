{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Surveil where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Surveil as Surveil

-- | Parun.Codec.PlayerQuantity's two fields, and the slot ELIDED when absent,
-- as Parun.Codec.Mill's is.
codec :: Codec.Codec Surveil.Surveil
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec Surveil.player
  quantity <- Fields.required "quantity" Quantity.codec Surveil.quantity
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Surveil.slot
  pure
    Surveil.MkSurveil
      { Surveil.player = player,
        Surveil.quantity = quantity,
        Surveil.slot = slot
      }
