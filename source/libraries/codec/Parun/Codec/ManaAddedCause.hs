module Parun.Codec.ManaAddedCause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaAddedCause as ManaAddedCause

codec :: Codec.Codec ManaAddedCause.ManaAddedCause
codec = Arm.enum
