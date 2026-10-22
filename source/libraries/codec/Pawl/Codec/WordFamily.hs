module Pawl.Codec.WordFamily where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.WordFamily as WordFamily

codec :: Codec.Codec WordFamily.WordFamily
codec = Arm.enum
