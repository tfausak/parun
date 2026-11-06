module Parun.Codec.NumberFloor where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.NumberFloor as NumberFloor

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec NumberFloor.NumberFloor
codec = Arm.enum
