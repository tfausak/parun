module Parun.Codec.ManaSpending where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaSpending as ManaSpending

codec :: Codec.Codec ManaSpending.ManaSpending
codec = Arm.enum
