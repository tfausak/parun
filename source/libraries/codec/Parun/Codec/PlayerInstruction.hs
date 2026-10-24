module Parun.Codec.PlayerInstruction where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerInstruction as PlayerInstruction

codec :: Codec.Codec PlayerInstruction.PlayerInstruction
codec = Arm.enum
