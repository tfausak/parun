module Parun.Codec.Prohibition where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Prohibition as Prohibition

codec :: Codec.Codec Prohibition.Prohibition
codec = Arm.enum
