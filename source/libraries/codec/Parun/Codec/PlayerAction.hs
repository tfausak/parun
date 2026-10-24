module Parun.Codec.PlayerAction where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerAction as PlayerAction

codec :: Codec.Codec PlayerAction.PlayerAction
codec = Arm.enum
