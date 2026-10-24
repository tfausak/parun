{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.VentureMarkerEntered where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.RoomIndex as RoomIndex
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.VentureMarkerEntered as VentureMarkerEntered

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec VentureMarkerEntered.VentureMarkerEntered
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec VentureMarkerEntered.player
  dungeon <- Fields.required "dungeon" ObjectId.codec VentureMarkerEntered.dungeon
  room <- Fields.required "room" RoomIndex.codec VentureMarkerEntered.room
  pure
    VentureMarkerEntered.MkVentureMarkerEntered
      { VentureMarkerEntered.player = player,
        VentureMarkerEntered.dungeon = dungeon,
        VentureMarkerEntered.room = room
      }
