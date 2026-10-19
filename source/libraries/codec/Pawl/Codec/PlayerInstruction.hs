module Pawl.Codec.PlayerInstruction where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.PlayerInstruction as PlayerInstruction

codec :: Codec.Codec PlayerInstruction.PlayerInstruction
codec = Arm.enum
