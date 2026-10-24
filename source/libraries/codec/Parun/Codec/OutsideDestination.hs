module Parun.Codec.OutsideDestination where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.OutsideDestination as OutsideDestination

codec :: Codec.Codec OutsideDestination.OutsideDestination
codec = Arm.enum
