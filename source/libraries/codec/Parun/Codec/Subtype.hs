module Parun.Codec.Subtype where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Subtype as Subtype

codec :: Codec.Codec Subtype.Subtype
codec = Arm.enum
