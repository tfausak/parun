module Parun.Codec.MulliganDecision where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MulliganDecision as MulliganDecision

codec :: Codec.Codec MulliganDecision.MulliganDecision
codec = Arm.enum
