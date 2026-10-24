module Parun.Codec.Zone where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Zone as Zone

codec :: Codec.Codec Zone.Zone
codec = Arm.enum
