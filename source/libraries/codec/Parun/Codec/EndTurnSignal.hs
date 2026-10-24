module Parun.Codec.EndTurnSignal where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EndTurnSignal as EndTurnSignal

codec :: Codec.Codec EndTurnSignal.EndTurnSignal
codec = Arm.enum
