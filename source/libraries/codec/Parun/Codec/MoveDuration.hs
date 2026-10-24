module Parun.Codec.MoveDuration where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MoveDuration as MoveDuration

codec :: Codec.Codec MoveDuration.MoveDuration
codec = Arm.enum
