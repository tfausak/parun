module Parun.Codec.HiddenZone where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.HiddenZone as HiddenZone

codec :: Codec.Codec HiddenZone.HiddenZone
codec = Arm.enum
