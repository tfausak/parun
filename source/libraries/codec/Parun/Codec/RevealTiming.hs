module Parun.Codec.RevealTiming where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RevealTiming as RevealTiming

codec :: Codec.Codec RevealTiming.RevealTiming
codec = Arm.enum
