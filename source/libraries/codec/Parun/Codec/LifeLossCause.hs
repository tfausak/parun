module Parun.Codec.LifeLossCause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LifeLossCause as LifeLossCause

codec :: Codec.Codec LifeLossCause.LifeLossCause
codec = Arm.enum
