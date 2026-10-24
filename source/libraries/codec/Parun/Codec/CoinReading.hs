module Parun.Codec.CoinReading where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CoinReading as CoinReading

codec :: Codec.Codec CoinReading.CoinReading
codec = Arm.enum
