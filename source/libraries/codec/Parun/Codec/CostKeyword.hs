module Parun.Codec.CostKeyword where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostKeyword as CostKeyword

codec :: Codec.Codec CostKeyword.CostKeyword
codec = Arm.enum
