module Parun.Codec.ColorMode where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ColorMode as ColorMode

codec :: Codec.Codec ColorMode.ColorMode
codec = Arm.enum
