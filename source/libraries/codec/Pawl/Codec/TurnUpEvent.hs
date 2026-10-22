module Pawl.Codec.TurnUpEvent where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.TurnUpEvent as TurnUpEvent

codec :: Codec.Codec TurnUpEvent.TurnUpEvent
codec = Arm.enum
