{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpeedDecrease where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpeedDecrease as SpeedDecrease

-- | A bare object keyed by the record's field names, Parun.Codec.Mill's shape.
-- The floor is ELIDED when it is 0, which is what a card printing no such
-- sentence says.
codec :: Codec.Codec SpeedDecrease.SpeedDecrease
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec SpeedDecrease.player
  quantity <- Fields.required "quantity" Quantity.codec SpeedDecrease.quantity
  floor_ <- Fields.defaulted "floor" 0 Common.natural SpeedDecrease.floor
  pure
    SpeedDecrease.MkSpeedDecrease
      { SpeedDecrease.player = player,
        SpeedDecrease.quantity = quantity,
        SpeedDecrease.floor = floor_
      }
