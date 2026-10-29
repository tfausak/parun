module Parun.Codec.LifeDirection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LifeDirection as LifeDirection

codec :: Codec.Codec LifeDirection.LifeDirection
codec = Arm.enum
