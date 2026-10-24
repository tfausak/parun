module Pawl.Codec.ColorMode where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ColorMode as ColorMode

codec :: Codec.Codec ColorMode.ColorMode
codec = Arm.enum
