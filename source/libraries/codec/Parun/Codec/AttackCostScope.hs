module Parun.Codec.AttackCostScope where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackCostScope as AttackCostScope

codec :: Codec.Codec AttackCostScope.AttackCostScope
codec = Arm.enum
