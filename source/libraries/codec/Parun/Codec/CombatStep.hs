module Parun.Codec.CombatStep where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CombatStep as CombatStep

codec :: Codec.Codec CombatStep.CombatStep
codec = Arm.enum
