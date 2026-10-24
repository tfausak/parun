module Parun.Codec.Designation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Designation as Designation

codec :: Codec.Codec Designation.Designation
codec = Arm.enum
