module Parun.Codec.TurnUpEvent where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnUpEvent as TurnUpEvent

codec :: Codec.Codec TurnUpEvent.TurnUpEvent
codec = Arm.enum
