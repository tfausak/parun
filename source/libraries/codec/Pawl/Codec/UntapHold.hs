module Pawl.Codec.UntapHold where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.UntapHold as UntapHold

codec :: Codec.Codec UntapHold.UntapHold
codec = Arm.enum
