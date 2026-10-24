module Parun.Codec.CastObligation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CastObligation as CastObligation

codec :: Codec.Codec CastObligation.CastObligation
codec = Arm.enum
