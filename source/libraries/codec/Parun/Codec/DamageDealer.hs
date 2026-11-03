module Parun.Codec.DamageDealer where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DamageDealer as DamageDealer

codec :: Codec.Codec DamageDealer.DamageDealer
codec = Arm.enum
