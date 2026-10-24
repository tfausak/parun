module Parun.Codec.DiceReading where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DiceReading as DiceReading

codec :: Codec.Codec DiceReading.DiceReading
codec = Arm.enum
