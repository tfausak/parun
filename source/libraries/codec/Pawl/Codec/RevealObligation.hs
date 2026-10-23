module Pawl.Codec.RevealObligation where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.RevealObligation as RevealObligation

codec :: Codec.Codec RevealObligation.RevealObligation
codec = Arm.enum
