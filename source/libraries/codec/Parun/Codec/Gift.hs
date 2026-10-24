module Parun.Codec.Gift where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Gift as Gift

codec :: Codec.Codec Gift.Gift
codec = Arm.enum
