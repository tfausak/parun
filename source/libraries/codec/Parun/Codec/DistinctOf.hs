module Parun.Codec.DistinctOf where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DistinctOf as DistinctOf

codec :: Codec.Codec DistinctOf.DistinctOf
codec = Arm.enum
