module Parun.Codec.Color where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Color as Color

codec :: Codec.Codec Color.Color
codec = Arm.enum
