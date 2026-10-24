module Parun.Codec.Daytime where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Daytime as Daytime

codec :: Codec.Codec Daytime.Daytime
codec = Arm.enum
