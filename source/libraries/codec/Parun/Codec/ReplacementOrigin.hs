module Parun.Codec.ReplacementOrigin where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin

codec :: Codec.Codec ReplacementOrigin.ReplacementOrigin
codec = Arm.enum
