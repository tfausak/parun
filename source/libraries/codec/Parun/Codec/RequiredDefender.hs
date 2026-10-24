module Parun.Codec.RequiredDefender where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RequiredDefender as RequiredDefender

codec :: Codec.Codec RequiredDefender.RequiredDefender
codec = Arm.enum
