module Parun.Codec.BlockRole where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.BlockRole as BlockRole

codec :: Codec.Codec BlockRole.BlockRole
codec = Arm.enum
