module Parun.Codec.PlaneswalkCause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlaneswalkCause as PlaneswalkCause

codec :: Codec.Codec PlaneswalkCause.PlaneswalkCause
codec = Arm.enum
