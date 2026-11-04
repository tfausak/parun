module Parun.Codec.CounterGrouping where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterGrouping as CounterGrouping

codec :: Codec.Codec CounterGrouping.CounterGrouping
codec = Arm.enum
