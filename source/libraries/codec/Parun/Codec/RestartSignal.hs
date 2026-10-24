module Parun.Codec.RestartSignal where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RestartSignal as RestartSignal

codec :: Codec.Codec RestartSignal.RestartSignal
codec = Arm.enum
