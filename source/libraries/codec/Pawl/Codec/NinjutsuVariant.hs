module Pawl.Codec.NinjutsuVariant where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.NinjutsuVariant as NinjutsuVariant

codec :: Codec.Codec NinjutsuVariant.NinjutsuVariant
codec = Arm.enum
