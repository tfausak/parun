module Parun.Codec.Uses where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Uses as Uses

codec :: Codec.Codec Uses.Uses
codec = Arm.enum
