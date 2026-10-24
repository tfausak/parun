module Parun.Codec.FaceDownReason where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.FaceDownReason as FaceDownReason

codec :: Codec.Codec FaceDownReason.FaceDownReason
codec = Arm.enum
