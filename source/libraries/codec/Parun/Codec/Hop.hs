module Parun.Codec.Hop where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Hop as Hop

codec :: Codec.Codec Hop.Hop
codec = Arm.enum
