module Parun.Codec.TriggerFrequency where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

codec :: Codec.Codec TriggerFrequency.TriggerFrequency
codec = Arm.enum
