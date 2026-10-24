module Parun.Codec.WordFamily where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.WordFamily as WordFamily

codec :: Codec.Codec WordFamily.WordFamily
codec = Arm.enum
