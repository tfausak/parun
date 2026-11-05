module Parun.Codec.ColorSpread where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ColorSpread as ColorSpread

-- | Nullary tags, Parun.Codec.AbilityKind's shape and for its reason.
codec :: Codec.Codec ColorSpread.ColorSpread
codec = Arm.enum
