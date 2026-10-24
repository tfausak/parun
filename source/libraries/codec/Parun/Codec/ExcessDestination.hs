module Parun.Codec.ExcessDestination where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ExcessDestination as ExcessDestination

codec :: Codec.Codec ExcessDestination.ExcessDestination
codec = Arm.enum
