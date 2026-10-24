module Parun.Codec.ConjureSelection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ConjureSelection as ConjureSelection

codec :: Codec.Codec ConjureSelection.ConjureSelection
codec = Arm.enum
