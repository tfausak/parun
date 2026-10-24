module Parun.Codec.LoopMembers where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LoopMembers as LoopMembers

codec :: Codec.Codec LoopMembers.LoopMembers
codec = Arm.enum
