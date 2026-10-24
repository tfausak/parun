module Parun.Codec.Regenerability where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Regenerability as Regenerability

codec :: Codec.Codec Regenerability.Regenerability
codec = Arm.enum
