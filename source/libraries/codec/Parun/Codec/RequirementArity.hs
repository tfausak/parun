module Parun.Codec.RequirementArity where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RequirementArity as RequirementArity

codec :: Codec.Codec RequirementArity.RequirementArity
codec = Arm.enum
