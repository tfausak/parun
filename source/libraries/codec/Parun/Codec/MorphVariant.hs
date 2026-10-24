module Parun.Codec.MorphVariant where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MorphVariant as MorphVariant

codec :: Codec.Codec MorphVariant.MorphVariant
codec = Arm.enum
