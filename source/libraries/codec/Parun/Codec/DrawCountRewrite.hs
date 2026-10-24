module Parun.Codec.DrawCountRewrite where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DrawCountRewrite as DrawCountRewrite

codec :: Codec.Codec DrawCountRewrite.DrawCountRewrite
codec = Arm.enum
