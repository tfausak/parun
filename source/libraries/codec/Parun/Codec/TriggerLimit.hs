module Parun.Codec.TriggerLimit where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TriggerLimit as TriggerLimit

codec :: Codec.Codec TriggerLimit.TriggerLimit
codec = Arm.enum
