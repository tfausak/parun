module Parun.Codec.RoomIndex where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.RoomIndex as RoomIndex

codec :: Codec.Codec RoomIndex.RoomIndex
codec = Common.wrapper Common.natural RoomIndex.MkRoomIndex RoomIndex.unwrap
