module Parun.Codec.ModeMemory where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ModeMemory as ModeMemory

codec :: Codec.Codec ModeMemory.ModeMemory
codec = Arm.enum
