module Parun.Codec.DiscardWay where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DiscardWay as DiscardWay

codec :: Codec.Codec DiscardWay.DiscardWay
codec = Arm.enum
