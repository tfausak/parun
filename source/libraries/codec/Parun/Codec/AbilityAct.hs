module Parun.Codec.AbilityAct where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AbilityAct as AbilityAct

-- | Nullary tags, Parun.Codec.AbilityKind's shape and for its reason.
codec :: Codec.Codec AbilityAct.AbilityAct
codec = Arm.enum
