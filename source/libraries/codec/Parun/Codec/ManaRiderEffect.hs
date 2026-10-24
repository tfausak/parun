module Parun.Codec.ManaRiderEffect where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaRiderEffect as ManaRiderEffect

codec :: Codec.Codec ManaRiderEffect.ManaRiderEffect
codec = Arm.enum
