module Pawl.Codec.PlaneswalkCause where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.PlaneswalkCause as PlaneswalkCause

codec :: Codec.Codec PlaneswalkCause.PlaneswalkCause
codec = Arm.enum
