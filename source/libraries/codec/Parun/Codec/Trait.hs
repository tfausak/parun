module Parun.Codec.Trait where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Trait as Trait

codec :: Codec.Codec Trait.Trait
codec = Arm.enum
