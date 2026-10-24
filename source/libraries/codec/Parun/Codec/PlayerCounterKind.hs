module Parun.Codec.PlayerCounterKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind

codec :: Codec.Codec PlayerCounterKind.PlayerCounterKind
codec = Arm.enum
