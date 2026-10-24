module Parun.Codec.Departure where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Departure as Departure

codec :: Codec.Codec Departure.Departure
codec = Arm.enum
