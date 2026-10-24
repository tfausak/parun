module Parun.Codec.Sacrificer where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Sacrificer as Sacrificer

codec :: Codec.Codec Sacrificer.Sacrificer
codec = Arm.enum
