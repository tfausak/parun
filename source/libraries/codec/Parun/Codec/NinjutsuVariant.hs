module Parun.Codec.NinjutsuVariant where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.NinjutsuVariant as NinjutsuVariant

codec :: Codec.Codec NinjutsuVariant.NinjutsuVariant
codec = Arm.enum
