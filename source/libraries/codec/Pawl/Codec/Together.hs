module Pawl.Codec.Together where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.Together as Together

codec :: Codec.Codec Together.Together
codec = Arm.enum
