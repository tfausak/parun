module Parun.Codec.Measure where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Measure as Measure

codec :: Codec.Codec Measure.Measure
codec = Arm.enum
