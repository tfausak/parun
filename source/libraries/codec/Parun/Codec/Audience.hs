module Parun.Codec.Audience where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Audience as Audience

codec :: Codec.Codec Audience.Audience
codec = Arm.enum
