module Pawl.Codec.TurnRole where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.TurnRole as TurnRole

codec :: Codec.Codec TurnRole.TurnRole
codec = Arm.enum
