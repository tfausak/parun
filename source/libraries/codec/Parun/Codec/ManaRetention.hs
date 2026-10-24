module Parun.Codec.ManaRetention where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaRetention as ManaRetention

codec :: Codec.Codec ManaRetention.ManaRetention
codec = Arm.enum
