module Parun.Codec.EquipTarget where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EquipTarget as EquipTarget

codec :: Codec.Codec EquipTarget.EquipTarget
codec = Arm.enum
