module Parun.Codec.PermanentAction where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PermanentAction as PermanentAction

codec :: Codec.Codec PermanentAction.PermanentAction
codec = Arm.enum
