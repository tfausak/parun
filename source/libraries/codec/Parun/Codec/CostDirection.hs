module Parun.Codec.CostDirection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostDirection as CostDirection

codec :: Codec.Codec CostDirection.CostDirection
codec = Arm.enum
