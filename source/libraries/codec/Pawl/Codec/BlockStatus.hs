module Pawl.Codec.BlockStatus where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.BlockStatus as BlockStatus

codec :: Codec.Codec BlockStatus.BlockStatus
codec = Arm.enum
