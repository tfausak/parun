module Parun.Codec.Undoing where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Undoing as Undoing

codec :: Codec.Codec Undoing.Undoing
codec = Arm.enum
