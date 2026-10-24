module Parun.Codec.Activator where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Activator as Activator

codec :: Codec.Codec Activator.Activator
codec = Arm.enum
