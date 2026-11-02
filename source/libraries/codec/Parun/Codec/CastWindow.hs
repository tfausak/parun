module Parun.Codec.CastWindow where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CastWindow as CastWindow

codec :: Codec.Codec CastWindow.CastWindow
codec = Arm.enum
