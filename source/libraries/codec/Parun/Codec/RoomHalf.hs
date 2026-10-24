module Parun.Codec.RoomHalf where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RoomHalf as RoomHalf

codec :: Codec.Codec RoomHalf.RoomHalf
codec = Arm.enum
