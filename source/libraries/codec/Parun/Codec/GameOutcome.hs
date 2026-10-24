module Parun.Codec.GameOutcome where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.GameOutcome as GameOutcome

codec :: Codec.Codec GameOutcome.GameOutcome
codec = Arm.enum
