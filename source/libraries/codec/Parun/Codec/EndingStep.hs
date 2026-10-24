module Parun.Codec.EndingStep where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EndingStep as EndingStep

codec :: Codec.Codec EndingStep.EndingStep
codec = Arm.enum
