module Parun.Codec.CounterSpread where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterSpread as CounterSpread

-- | Nullary tags, Parun.Codec.AbilityKind's shape and for its reason.
codec :: Codec.Codec CounterSpread.CounterSpread
codec = Arm.enum
