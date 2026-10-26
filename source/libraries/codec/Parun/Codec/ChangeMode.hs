module Parun.Codec.ChangeMode where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ChangeMode as ChangeMode

codec :: Codec.Codec ChangeMode.ChangeMode
codec = Arm.enum
