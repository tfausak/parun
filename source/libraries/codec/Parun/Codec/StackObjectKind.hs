module Parun.Codec.StackObjectKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.StackObjectKind as StackObjectKind

codec :: Codec.Codec StackObjectKind.StackObjectKind
codec = Arm.enum
