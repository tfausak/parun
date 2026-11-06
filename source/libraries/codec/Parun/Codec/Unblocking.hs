module Parun.Codec.Unblocking where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Unblocking as Unblocking

codec :: Codec.Codec Unblocking.Unblocking
codec = Arm.enum
