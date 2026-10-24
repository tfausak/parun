module Parun.Codec.Counterability where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Counterability as Counterability

codec :: Codec.Codec Counterability.Counterability
codec = Arm.enum
