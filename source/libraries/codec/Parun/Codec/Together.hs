module Parun.Codec.Together where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Together as Together

codec :: Codec.Codec Together.Together
codec = Arm.enum
