module Parun.Codec.FlipOutcome where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.FlipOutcome as FlipOutcome

codec :: Codec.Codec FlipOutcome.FlipOutcome
codec = Arm.enum
