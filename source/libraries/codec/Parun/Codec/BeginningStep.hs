module Parun.Codec.BeginningStep where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.BeginningStep as BeginningStep

codec :: Codec.Codec BeginningStep.BeginningStep
codec = Arm.enum
