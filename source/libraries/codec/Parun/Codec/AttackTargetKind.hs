module Parun.Codec.AttackTargetKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackTargetKind as AttackTargetKind

codec :: Codec.Codec AttackTargetKind.AttackTargetKind
codec = Arm.enum
