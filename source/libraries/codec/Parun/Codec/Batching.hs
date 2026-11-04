module Parun.Codec.Batching where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Batching as Batching

codec :: Codec.Codec Batching.Batching
codec = Arm.enum
