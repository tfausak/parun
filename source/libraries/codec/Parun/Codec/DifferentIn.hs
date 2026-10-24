module Parun.Codec.DifferentIn where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DifferentIn as DifferentIn

codec :: Codec.Codec DifferentIn.DifferentIn
codec = Arm.enum
