{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SlotPerPlayer where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SlotPerPlayer as SlotPerPlayer

-- | A bare object keyed by the record's field names, both required: "for each
-- opponent" and "for each player" are different printed sentences.
codec :: Codec.Codec SlotPerPlayer.SlotPerPlayer
codec = Fields.object $ do
  players <- Fields.required "players" PlayerRelation.codec SlotPerPlayer.players
  slot <- Fields.required "slot" SlotName.codec SlotPerPlayer.slot
  pure
    SlotPerPlayer.MkSlotPerPlayer
      { SlotPerPlayer.players = players,
        SlotPerPlayer.slot = slot
      }
