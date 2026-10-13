module Pawl.Codec.GameOutcome where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.GameOutcome as GameOutcome

codec :: Codec.Codec GameOutcome.GameOutcome
codec = Arm.enum
