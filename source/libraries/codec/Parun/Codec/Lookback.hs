module Parun.Codec.Lookback where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Lookback as Lookback

codec :: Codec.Codec Lookback.Lookback
codec = Arm.enum
