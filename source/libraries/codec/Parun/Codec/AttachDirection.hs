module Parun.Codec.AttachDirection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttachDirection as AttachDirection

codec :: Codec.Codec AttachDirection.AttachDirection
codec = Arm.enum
