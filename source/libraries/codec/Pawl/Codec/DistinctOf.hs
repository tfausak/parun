module Pawl.Codec.DistinctOf where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.DistinctOf as DistinctOf

codec :: Codec.Codec DistinctOf.DistinctOf
codec = Arm.enum
