module Parun.Codec.DamageKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DamageKind as DamageKind

codec :: Codec.Codec DamageKind.DamageKind
codec = Arm.enum
