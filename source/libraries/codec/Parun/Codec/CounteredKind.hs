module Parun.Codec.CounteredKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounteredKind as CounteredKind

codec :: Codec.Codec CounteredKind.CounteredKind
codec = Arm.enum
