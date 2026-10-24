module Parun.Codec.Comparison where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Comparison as Comparison

codec :: Codec.Codec Comparison.Comparison
codec = Arm.enum
