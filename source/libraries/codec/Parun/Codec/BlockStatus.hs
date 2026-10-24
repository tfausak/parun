module Parun.Codec.BlockStatus where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.BlockStatus as BlockStatus

codec :: Codec.Codec BlockStatus.BlockStatus
codec = Arm.enum
