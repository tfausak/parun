module Parun.Codec.CoinFace where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CoinFace as CoinFace

codec :: Codec.Codec CoinFace.CoinFace
codec = Arm.enum
