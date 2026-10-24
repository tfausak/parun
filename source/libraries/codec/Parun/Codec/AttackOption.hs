module Parun.Codec.AttackOption where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackOption as AttackOption

codec :: Codec.Codec AttackOption.AttackOption
codec = Arm.enum
