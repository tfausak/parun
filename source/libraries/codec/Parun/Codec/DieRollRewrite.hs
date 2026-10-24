module Parun.Codec.DieRollRewrite where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DieRollRewrite as DieRollRewrite

codec :: Codec.Codec DieRollRewrite.DieRollRewrite
codec = Arm.enum
