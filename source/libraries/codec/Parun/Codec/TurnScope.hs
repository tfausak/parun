module Parun.Codec.TurnScope where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnScope as TurnScope

codec :: Codec.Codec TurnScope.TurnScope
codec = Arm.enum
