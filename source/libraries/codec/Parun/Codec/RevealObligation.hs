module Parun.Codec.RevealObligation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RevealObligation as RevealObligation

codec :: Codec.Codec RevealObligation.RevealObligation
codec = Arm.enum
