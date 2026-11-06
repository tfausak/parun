module Parun.Codec.TurnResume where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnResume as TurnResume

codec :: Codec.Codec TurnResume.TurnResume
codec = Arm.enum
