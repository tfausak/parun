module Parun.Codec.DestructionRewrite where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DestructionRewrite as DestructionRewrite

codec :: Codec.Codec DestructionRewrite.DestructionRewrite
codec = Arm.enum
