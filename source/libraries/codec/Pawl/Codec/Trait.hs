module Pawl.Codec.Trait where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.Trait as Trait

codec :: Codec.Codec Trait.Trait
codec = Arm.enum
