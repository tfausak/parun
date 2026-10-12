module Pawl.Codec.Audience where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.Audience as Audience

codec :: Codec.Codec Audience.Audience
codec = Arm.enum
