module Parun.Codec.Rounding where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Rounding as Rounding

codec :: Codec.Codec Rounding.Rounding
codec = Arm.enum
