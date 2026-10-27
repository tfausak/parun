module Parun.Codec.SubtypeFamily where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.SubtypeFamily as SubtypeFamily

codec :: Codec.Codec SubtypeFamily.SubtypeFamily
codec = Arm.enum
