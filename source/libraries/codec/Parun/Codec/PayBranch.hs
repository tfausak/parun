module Parun.Codec.PayBranch where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PayBranch as PayBranch

codec :: Codec.Codec PayBranch.PayBranch
codec = Arm.enum
