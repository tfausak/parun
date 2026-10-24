module Parun.Codec.DamageDirection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DamageDirection as DamageDirection

codec :: Codec.Codec DamageDirection.DamageDirection
codec = Arm.enum
