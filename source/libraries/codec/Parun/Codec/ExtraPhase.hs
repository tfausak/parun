module Parun.Codec.ExtraPhase where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ExtraPhase as ExtraPhase

codec :: Codec.Codec ExtraPhase.ExtraPhase
codec = Arm.enum
