module Parun.Codec.PayObligation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PayObligation as PayObligation

codec :: Codec.Codec PayObligation.PayObligation
codec = Arm.enum
