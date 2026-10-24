module Parun.Codec.TurnRole where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnRole as TurnRole

codec :: Codec.Codec TurnRole.TurnRole
codec = Arm.enum
