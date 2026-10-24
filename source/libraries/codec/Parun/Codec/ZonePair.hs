module Parun.Codec.ZonePair where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ZonePair as ZonePair

codec :: Codec.Codec ZonePair.ZonePair
codec = Arm.enum
